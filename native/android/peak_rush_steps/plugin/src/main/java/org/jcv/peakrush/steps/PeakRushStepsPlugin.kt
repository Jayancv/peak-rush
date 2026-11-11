package org.jcv.peakrush.steps

import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Daily step totals from Health Connect for Peak Rush (GDScript side:
 * scenes/steps/health_connect_step_provider.gd). Calls return at once; answers come
 * back as signals on Godot's thread. Read-only, steps only, read only while the game is open.
 */
class PeakRushStepsPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "PeakRushSteps"
        private const val REQUEST_CODE = 0x5E75
        private const val PROVIDER = "com.google.android.apps.healthdata"

        // Must match StepProvider.Status in GDScript.
        private const val STATUS_UNSUPPORTED = 0
        private const val STATUS_NEEDS_APP = 1
        private const val STATUS_READY = 2

        private val PERMISSIONS = setOf(HealthPermission.getReadPermission(StepsRecord::class))
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val permissionContract = PermissionController.createRequestPermissionResultContract()

    override fun getPluginName(): String = "PeakRushSteps"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("access_result", Boolean::class.javaObjectType),
        SignalInfo("days_read", Int::class.javaObjectType, String::class.java, Boolean::class.javaObjectType),
    )

    @UsedByGodot
    fun getStatus(): Int {
        val ctx = activity ?: return STATUS_UNSUPPORTED
        return when (HealthConnectClient.getSdkStatus(ctx, PROVIDER)) {
            HealthConnectClient.SDK_AVAILABLE -> STATUS_READY
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> STATUS_NEEDS_APP
            else -> STATUS_UNSUPPORTED
        }
    }

    /** Shows the Health Connect permission screen unless steps are already allowed. */
    @UsedByGodot
    fun requestAccess() {
        val act = activity
        val client = client()
        if (act == null || client == null) {
            emitAccess(false)
            return
        }
        scope.launch {
            try {
                if (client.permissionController.getGrantedPermissions().containsAll(PERMISSIONS)) {
                    emitAccess(true)
                } else {
                    act.startActivityForResult(permissionContract.createIntent(act, PERMISSIONS), REQUEST_CODE)
                }
            } catch (e: Exception) {
                Log.w(TAG, "requestAccess failed", e)
                emitAccess(false)
            }
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_CODE) return
        val granted = permissionContract.parseResult(resultCode, data)
        emitAccess(granted.containsAll(PERMISSIONS))
    }

    /**
     * request: {"dates": ["YYYY-MM-DD", ...], "since_unix": seconds}. Dates are local days;
     * steps before since_unix don't count. Answers days_read(id, {"date": steps}, ok).
     * Aggregation lets Health Connect de-duplicate phone and watch steps.
     */
    @UsedByGodot
    fun readDays(id: Int, request: String) {
        val client = client()
        if (client == null) {
            emitDays(id, "{}", false)
            return
        }
        scope.launch {
            try {
                if (!client.permissionController.getGrantedPermissions().containsAll(PERMISSIONS)) {
                    emitDays(id, "{}", false)
                    return@launch
                }
                val req = JSONObject(request)
                val dates = req.getJSONArray("dates")
                val since = Instant.ofEpochSecond(req.getLong("since_unix"))
                val zone = ZoneId.systemDefault()
                val out = JSONObject()
                for (i in 0 until dates.length()) {
                    val key = dates.getString(i)
                    val day = LocalDate.parse(key)
                    val start = maxOf(day.atStartOfDay(zone).toInstant(), since)
                    val end = minOf(day.plusDays(1).atStartOfDay(zone).toInstant(), Instant.now())
                    if (!start.isBefore(end)) {
                        out.put(key, 0L)
                        continue
                    }
                    val result = client.aggregate(
                        AggregateRequest(setOf(StepsRecord.COUNT_TOTAL), TimeRangeFilter.between(start, end))
                    )
                    out.put(key, result[StepsRecord.COUNT_TOTAL] ?: 0L)
                }
                emitDays(id, out.toString(), true)
            } catch (e: Exception) {
                Log.w(TAG, "readDays failed", e)
                emitDays(id, "{}", false)
            }
        }
    }

    /** Health Connect missing or outdated (Android 13 and older): its Play Store page. */
    @UsedByGodot
    fun openStore() {
        val act = activity ?: return
        try {
            val uri = Uri.parse("market://details?id=$PROVIDER&url=healthconnect%3A%2F%2Fonboarding")
            act.startActivity(
                Intent(Intent.ACTION_VIEW, uri)
                    .setPackage("com.android.vending")
                    .putExtra("overlay", true)
                    .putExtra("callerId", act.packageName)
            )
        } catch (e: Exception) {
            Log.w(TAG, "openStore failed", e)
        }
    }

    private fun client(): HealthConnectClient? {
        val ctx = activity ?: return null
        if (HealthConnectClient.getSdkStatus(ctx, PROVIDER) != HealthConnectClient.SDK_AVAILABLE) return null
        return HealthConnectClient.getOrCreate(ctx)
    }

    private fun emitAccess(granted: Boolean) {
        runOnRenderThread { emitSignal("access_result", granted) }
    }

    private fun emitDays(id: Int, json: String, ok: Boolean) {
        runOnRenderThread { emitSignal("days_read", id, json, ok) }
    }
}
