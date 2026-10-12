package com.synckord.horyzontal

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// FlutterFragmentActivity: local_auth needs a FragmentActivity for BiometricPrompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "horyzontal/heading")
            .setStreamHandler(HeadingStream(this))
    }
}

/**
 * `horyzontal/heading`: magnetic heading of the top edge of the screen from
 * the rotation vector sensor (fused magnetometer, accelerometer, gyroscope).
 * Accuracy is the sensor's own estimate in degrees when it reports one,
 * otherwise derived from the calibration status; -1 means uncalibrated.
 */
class HeadingStream(private val activity: MainActivity) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var sink: EventChannel.EventSink? = null
    private var status = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
    private val rotation = FloatArray(9)
    private val remapped = FloatArray(9)
    private val orientation = FloatArray(3)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (sensor == null) {
            events.error("unavailable", "No rotation vector sensor", null)
            return
        }
        sink = events
        sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        status = accuracy
    }

    override fun onSensorChanged(event: SensorEvent) {
        SensorManager.getRotationMatrixFromVector(rotation, event.values)
        val (x, y) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotation, x, y, remapped)
        SensorManager.getOrientation(remapped, orientation)
        var heading = Math.toDegrees(orientation[0].toDouble())
        if (heading < 0) heading += 360.0

        val estimate = if (event.values.size > 4) Math.toDegrees(event.values[4].toDouble()) else -1.0
        val accuracy = when {
            status == SensorManager.SENSOR_STATUS_UNRELIABLE -> -1.0
            estimate > 0 -> estimate
            status == SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 5.0
            status == SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 15.0
            else -> 30.0
        }
        sink?.success(mapOf("heading" to heading, "accuracy" to accuracy))
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) activity.display?.rotation ?: Surface.ROTATION_0
        else activity.windowManager.defaultDisplay.rotation
}
