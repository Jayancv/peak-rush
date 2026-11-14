package org.jcv.peakrush.steps

import androidx.core.content.FileProvider

/**
 * Our own FileProvider class for sharing postcard pictures. Godot's Android template already
 * declares androidx.core.content.FileProvider, and the manifest merger can't hold two
 * providers with the same class name, so the plugin registers this subclass instead.
 */
class ShareFileProvider : FileProvider(R.xml.peak_rush_share_paths)
