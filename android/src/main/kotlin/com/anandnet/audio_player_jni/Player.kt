package com.anandnet.audio_player_jni

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.LoadControl
import com.google.errorprone.annotations.Keep
import com.google.gson.Gson
import java.util.concurrent.FutureTask

@UnstableApi
@Keep
class AudioPlayerJni(context: Context) {
    private var init : Boolean = true;
    private val loadControl: LoadControl = DefaultLoadControl.Builder()
        .setBufferDurationsMs(
            30000,
            60000,
            200,
            500
        )
        .build()
    private val exoPlayer: ExoPlayer =
        ExoPlayer.Builder(context).setLoadControl(loadControl).build()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun getCurrentState(): Int {
        val future = FutureTask {
            exoPlayer.playbackState
        }
        mainHandler.post(future)
        return future.get()
    }

    fun getCurrentError(): String? {
        val future = FutureTask {
            val error = exoPlayer.playerError ?: return@FutureTask null

            val map: MutableMap<String, Any> = mutableMapOf(
                "error" to mutableMapOf(
                    "code" to error.errorCode,
                    "message" to error.message,
                    "stackTrace" to error.stackTraceToString()
                )
            )

            return@FutureTask map
        }
        mainHandler.post(future)
        return Gson().toJson(future.get())
    }

    fun getCurrentPosition(): Long {
        val future = FutureTask {
            exoPlayer.currentPosition
        }
        mainHandler.post(future)
        return future.get()
    }

    fun getDuration(): Long {
        val future = FutureTask {
            exoPlayer.duration
        }
        mainHandler.post(future)
        return future.get()
    }

    fun getBufferedPosition(): Long {
        val future = FutureTask {
            exoPlayer.bufferedPosition
        }
        mainHandler.post(future)
        return future.get()
    }

    fun getAllStates(): String? {
        val future = FutureTask {
            val error = exoPlayer.playerError
            val errorMap = error?.let {
                mutableMapOf(
                    "code" to error.errorCode,
                    "message" to error.message,
                    "stackTrace" to error.stackTraceToString()
                )
            }

            mutableMapOf(
                "isPlaying" to exoPlayer.isPlaying,
                "currentIndex" to exoPlayer.currentMediaItemIndex,
                "state" to exoPlayer.playbackState,
                "error" to errorMap,
                "currentPosition" to exoPlayer.currentPosition,
                "duration" to exoPlayer.duration,
                "bufferedPosition" to exoPlayer.bufferedPosition
            )
        }
        mainHandler.post(future)
        return Gson().toJson(future.get())
    }

    fun setUrl(url: String, autoPlay: Boolean) {
        mainHandler.post {
            exoPlayer.setMediaItem(MediaItem.fromUri(url))
            exoPlayer.prepare()
            if (autoPlay) exoPlayer.play()
        }
    }

    fun addMediaItem(mediaItem: MediaItem, index: Int?) {
        mainHandler.post {
            if (index == null) {
                exoPlayer.addMediaItem(mediaItem)
            } else {
                exoPlayer.addMediaItem(index, mediaItem)
            }
            if(init){
                exoPlayer.prepare()
                init = false;
            }
        }
    }

    fun addMediaItems(mediaItems: List<MediaItem>, index: Int?) {
        mainHandler.post {
            if (index == null) {
                exoPlayer.addMediaItems(mediaItems)
            } else {
                exoPlayer.addMediaItems(index, mediaItems)
            }
            if(init){
                exoPlayer.prepare()
                init = false;
            }
        }
    }

    fun moveMediaItem(fromIndex: Int, toIndex: Int) {
        mainHandler.post {
            if (fromIndex in 0 until exoPlayer.mediaItemCount && toIndex in 0 until exoPlayer.mediaItemCount) {
                exoPlayer.moveMediaItem(fromIndex, toIndex)
            }
        }
    }

    fun removeMediaItem(index: Int) {
        mainHandler.post {
            exoPlayer.removeMediaItem(index)
        }
    }

    fun removeMediaItemRange(fromIndex: Int, toIndex: Int) {
        mainHandler.post {
            exoPlayer.removeMediaItems(fromIndex, toIndex)
        }
    }

    fun removeAllMediaItems() {
        mainHandler.post {
            exoPlayer.clearMediaItems()
        }
    }

    fun getPlayList(): String {
        val futureTask = FutureTask {
            val mediaItems = mutableListOf<String>()
            val mediaItemCount = exoPlayer.mediaItemCount

            for (i in 0 until mediaItemCount) {
                exoPlayer.getMediaItemAt(i)
                    .let { mediaItems.add(it.localConfiguration?.uri.toString()) }
            }
            return@FutureTask mediaItems
        }
        mainHandler.post(futureTask)
        return Gson().toJson(futureTask.get())
    }

    fun play() {
        mainHandler.post {
            if (!exoPlayer.isPlaying && exoPlayer.currentMediaItem != null) {
                exoPlayer.play()
            }
        }
    }

    fun retryPlay() {
        mainHandler.post {
            val currentMediaItem = exoPlayer.currentMediaItem
            val currentPos = exoPlayer.currentPosition
            exoPlayer.stop()
            if (currentMediaItem != null) {
                //exoPlayer.setMediaItem(currentMediaItem)
                exoPlayer.prepare()
                exoPlayer.seekTo(currentPos)
                exoPlayer.play()
            }
        }
    }

    fun playPause() {
        mainHandler.post {
            if (exoPlayer.isPlaying) {
                exoPlayer.pause()
            } else {
                if (exoPlayer.currentMediaItem != null) {
                    exoPlayer.play()
                }
            }
        }
    }

    fun pause() {
        mainHandler.post {
            if (exoPlayer.isPlaying) {
                exoPlayer.pause()
            }
        }
    }

    fun skipToPrevious() {
        mainHandler.post {
            exoPlayer.seekToPreviousMediaItem()
        }
    }

    fun skipToNext() {
        mainHandler.post {
            exoPlayer.seekToNextMediaItem()
        }
    }

    fun seekTo(duration: Long, index: Int?) {
        mainHandler.post {
            if (index == null) {
                exoPlayer.seekTo(duration)
            } else {
                exoPlayer.seekTo(index, duration)
            }
        }
    }


    fun toggleRepeatMode(mode: Int) {
        mainHandler.post {
            exoPlayer.repeatMode = mode
        }
    }

    fun getRepeatMode(): Int {
        val futureTask = FutureTask {
            return@FutureTask exoPlayer.repeatMode
        }
        mainHandler.post(futureTask)
        return futureTask.get()
    }

    fun toggleShuffleMode(enable: Boolean) {
        mainHandler.post {
            exoPlayer.shuffleModeEnabled = enable
        }
    }

    fun isShuffleModeEnabled(): Boolean {
        val futureTask = FutureTask {
            return@FutureTask exoPlayer.shuffleModeEnabled
        }
        mainHandler.post(futureTask)
        return futureTask.get()
    }

    fun toggleSkipSilence(enable: Boolean) {
        mainHandler.post {
            exoPlayer.skipSilenceEnabled = enable
        }
    }

    fun isSkipSilenceEnabled(): Boolean {
        val futureTask = FutureTask {
            return@FutureTask exoPlayer.skipSilenceEnabled
        }
        mainHandler.post(futureTask)
        return futureTask.get()
    }

    fun getPlayerSessionId(): Int {
        val futureTask = FutureTask {
            return@FutureTask exoPlayer.audioSessionId
        }
        mainHandler.post(futureTask)
        return futureTask.get()
    }

    fun stop() {
        mainHandler.post {
            exoPlayer.stop()
        }
    }

    fun release() {
        mainHandler.post {
            exoPlayer.release()
        }
    }
}
