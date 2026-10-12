package com.synckord.horyzontal

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `horyzontal/wifi`: LocalOnlyHotspot host and WifiNetworkSpecifier /
 * WifiManager client for layer transfer. Ported from the stage 0 spike, where
 * it was tested between a POCO F3 (Android 16) and an iPhone.
 */
class WifiLink(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var legacyNetworkId: Int? = null
    private var pendingPermissions: MethodChannel.Result? = null

    private val wifi by lazy { activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager }
    private val connectivity by lazy { activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "horyzontal/wifi")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startHotspot" -> startHotspot(result)
                        "stopHotspot" -> { stopHotspot(); result.success(null) }
                        "join" -> join(call, result)
                        "leave" -> { leave(); result.success(null) }
                        "requestPermissions" -> requestWifiPermissions(call.argument<Boolean>("camera") == true, result)
                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("permission", e.message, null)
                }
            }
    }

    fun dispose() {
        stopHotspot()
        leave()
    }

    // Android 13+ gates the Wi-Fi APIs behind NEARBY_WIFI_DEVICES, 8-12 behind location.
    private fun requestWifiPermissions(camera: Boolean, result: MethodChannel.Result) {
        val wanted = mutableListOf(
            if (Build.VERSION.SDK_INT >= 33) Manifest.permission.NEARBY_WIFI_DEVICES
            else Manifest.permission.ACCESS_FINE_LOCATION
        )
        if (camera) wanted += Manifest.permission.CAMERA
        val missing = wanted.filter { activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty()) {
            result.success(wanted.associateWith { true })
            return
        }
        pendingPermissions?.error("superseded", null, null)
        pendingPermissions = result
        activity.requestPermissions(missing.toTypedArray(), PERMISSIONS_REQUEST)
    }

    /** Forwarded from the activity; true when it was ours. */
    fun onPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray): Boolean {
        if (code != PERMISSIONS_REQUEST) return false
        pendingPermissions?.success(permissions.indices.associate {
            permissions[it] to (grants[it] == PackageManager.PERMISSION_GRANTED)
        })
        pendingPermissions = null
        return true
    }

    // Host: LocalOnlyHotspot (API 26+). SSID and passphrase are random, chosen by the system.
    private fun startHotspot(result: MethodChannel.Result) {
        stopHotspot()
        wifi.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
            override fun onStarted(r: WifiManager.LocalOnlyHotspotReservation) {
                reservation = r
                val info: Map<String, Any?> = if (Build.VERSION.SDK_INT >= 30) {
                    val c = r.softApConfiguration
                    @Suppress("DEPRECATION")
                    val ssid = if (Build.VERSION.SDK_INT >= 33) c.wifiSsid?.toString() else c.ssid
                    mapOf("ssid" to unquote(ssid), "psk" to c.passphrase, "security" to c.securityType)
                } else {
                    @Suppress("DEPRECATION")
                    val c = r.wifiConfiguration!!
                    @Suppress("DEPRECATION")
                    mapOf("ssid" to unquote(c.SSID), "psk" to unquote(c.preSharedKey), "security" to 1)
                }
                result.success(info)
            }

            override fun onFailed(reason: Int) {
                // 1 no channel, 2 generic, 3 incompatible mode (tethering on), 4 tethering disallowed
                result.error("hotspot_failed", "LocalOnlyHotspot failed, reason $reason", reason)
            }

            override fun onStopped() {
                reservation = null
            }
        }, main)
    }

    private fun stopHotspot() {
        reservation?.close()
        reservation = null
    }

    // Client: join the host's network.
    private fun join(call: MethodCall, result: MethodChannel.Result) {
        val ssid = call.argument<String>("ssid")!!
        val psk = call.argument<String>("psk")!!
        val security = call.argument<Int>("security") ?: 1
        leave()
        if (Build.VERSION.SDK_INT >= 29) joinWithSpecifier(ssid, psk, security, result)
        else joinLegacy(ssid, psk, result)
    }

    private fun joinWithSpecifier(ssid: String, psk: String, security: Int, result: MethodChannel.Result) {
        val spec = WifiNetworkSpecifier.Builder().setSsid(ssid).apply {
            // 3 = WPA3-SAE only; WPA2 and WPA3 transition both accept a WPA2 client.
            if (security == 3) setWpa3Passphrase(psk) else setWpa2Passphrase(psk)
        }.build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(spec)
            .build()
        var answered = false
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                // Route this process (and Dart's sockets) through the hotspot.
                connectivity.bindProcessToNetwork(network)
                main.post { if (!answered) { answered = true; result.success(null) } }
            }

            override fun onUnavailable() {
                main.post {
                    if (!answered) { answered = true; result.error("join_failed", "network unavailable or declined", null) }
                }
            }
        }
        networkCallback = cb
        connectivity.requestNetwork(request, cb, 60_000)
    }

    @Suppress("DEPRECATION")
    private fun joinLegacy(ssid: String, psk: String, result: MethodChannel.Result) {
        val conf = WifiConfiguration().apply {
            SSID = "\"$ssid\""
            preSharedKey = "\"$psk\""
        }
        val id = wifi.addNetwork(conf)
        if (id == -1) {
            result.error("join_failed", "addNetwork failed", null)
            return
        }
        legacyNetworkId = id
        wifi.disconnect()
        wifi.enableNetwork(id, true)
        wifi.reconnect()
        result.success(null) // association is async; Dart retries the TCP connect
    }

    private fun leave() {
        networkCallback?.let {
            connectivity.bindProcessToNetwork(null)
            runCatching { connectivity.unregisterNetworkCallback(it) }
        }
        networkCallback = null
        legacyNetworkId?.let {
            @Suppress("DEPRECATION")
            wifi.removeNetwork(it)
        }
        legacyNetworkId = null
    }

    private fun unquote(s: String?): String = s?.removeSurrounding("\"") ?: ""

    companion object {
        private const val PERMISSIONS_REQUEST = 4201
    }
}
