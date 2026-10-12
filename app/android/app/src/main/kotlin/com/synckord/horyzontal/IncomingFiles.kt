package com.synckord.horyzontal

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.io.File

/**
 * `horyzontal/incoming`: files opened with the app (VIEW) or shared to it
 * (SEND / SEND_MULTIPLE) are copied into the cache and their paths passed to
 * Dart, which asks the user before importing anything.
 */
class IncomingFiles(private val activity: Activity) : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private val pending = mutableListOf<String>()

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, "horyzontal/incoming").setStreamHandler(this)
    }

    fun handle(intent: Intent?) {
        val uris = when (intent?.action) {
            Intent.ACTION_VIEW -> listOfNotNull(intent.data)
            Intent.ACTION_SEND -> listOfNotNull(stream(intent))
            Intent.ACTION_SEND_MULTIPLE -> streams(intent)
            else -> emptyList()
        }
        for (uri in uris) {
            val path = runCatching { copy(uri) }.getOrNull() ?: continue
            sink?.success(path) ?: pending.add(path)
        }
    }

    @Suppress("DEPRECATION")
    private fun stream(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streams(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)) ?: emptyList()

    private fun copy(uri: Uri): String? {
        val resolver = activity.contentResolver
        var name = uri.lastPathSegment?.substringAfterLast('/') ?: "file"
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0)?.let { name = it }
        }
        // The name comes from another app: keep only a safe last segment.
        name = name.substringAfterLast('/').replace(Regex("[^\\p{L}\\p{N}._ -]"), "_").take(120)
        val dir = File(activity.cacheDir, "incoming").apply { mkdirs() }
        val dest = File(dir, name)
        resolver.openInputStream(uri)?.use { input ->
            dest.outputStream().use { out ->
                // Imports refuse anything this large anyway.
                val limit = 64L * 1024 * 1024
                val copied = input.copyTo(out)
                if (copied > limit) { dest.delete(); return null }
            }
        } ?: return null
        return dest.absolutePath
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        pending.forEach { events.success(it) }
        pending.clear()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
