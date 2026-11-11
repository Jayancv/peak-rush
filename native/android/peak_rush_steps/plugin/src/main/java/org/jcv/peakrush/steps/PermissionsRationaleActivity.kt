package org.jcv.peakrush.steps

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

/**
 * Health Connect opens this to show why the game wants step data; it won't offer the
 * permission without it. Plain text, no layout files. The text is in res/values/strings.xml
 * (Android resources, since this screen runs outside the game).
 */
class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setTitle(R.string.peak_rush_steps_rationale_title)
        val pad = (24 * resources.displayMetrics.density).toInt()
        setContentView(TextView(this).apply {
            setPadding(pad, pad, pad, pad)
            textSize = 16f
            setText(R.string.peak_rush_steps_rationale_body)
        })
    }
}
