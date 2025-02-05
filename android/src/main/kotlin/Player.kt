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
    private var init : Boolean = true
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
        return commonGet { exoPlayer.playbackState }
    }

    fun getCurrentError(): String? {
        val result = commonGet {
            val error = exoPlayer.playerError?.let {
                mutableMapOf(
                    "error" to mutableMapOf(
                        "code" to it.errorCode,
                        "message" to it.message,
                        "stackTrace" to it.stackTraceToString()
                    )
                )
            }
            error
        }
        return Gson().toJson(result)
    }

    fun getCurrentPosition(): Long {
        return commonGet { exoPlayer.currentPosition }
    }

    fun getDuration(): Long {
        return commonGet { exoPlayer.duration }
    }

    fun getBufferedPosition(): Long {
        return commonGet { exoPlayer.bufferedPosition }
    }

    fun getAllStates(): String? {
        val result = commonGet {
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
                "bufferedPosition" to exoPlayer.bufferedPosition,
                "shuffleModeEnabled" to exoPlayer.shuffleModeEnabled,
                "repeatMode" to exoPlayer.repeatMode
            )
        }
        return Gson().toJson(result)
    }

    fun setUrl(url: String, autoPlay: Boolean) {
        mainHandler.post {
            exoPlayer.setMediaItem(MediaItem.fromUri(url))
            exoPlayer.prepare()
            if (autoPlay) exoPlayer.play()
        }
    }

    fun addMediaItem(url:String, index: Int?) {
        mainHandler.post {
            val mediaItem = MediaItem.fromUri(url)
            if (index == null) {
                exoPlayer.addMediaItem(mediaItem)
            } else {
                exoPlayer.addMediaItem(index, mediaItem)
            }
            if(init){
                exoPlayer.prepare()
                init = false
            }
        }
    }

    fun addMediaItems(urls: String, index: Int?) {
        val mediaItems = Gson().fromJson(urls, Array<String>::class.java)
            .map { MediaItem.fromUri(it) }
        mainHandler.post {
            if (index == null) {
                exoPlayer.addMediaItems(mediaItems)
            } else {
                exoPlayer.addMediaItems(index, mediaItems)
            }
            if(init){
                exoPlayer.prepare()
                init = false
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
        val result = commonGet {
            val mediaItems = mutableListOf<String>()
            val mediaItemCount = exoPlayer.mediaItemCount

            for (i in 0 until mediaItemCount) {
                exoPlayer.getMediaItemAt(i)
                    .let { mediaItems.add(it.localConfiguration?.uri.toString()) }
            }
             mediaItems
        }

        return Gson().toJson(result)
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
        return commonGet { exoPlayer.repeatMode }
    }

    fun toggleShuffleMode(enable: Boolean) {
        mainHandler.post {
            exoPlayer.shuffleModeEnabled = enable
        }
    }

    fun isShuffleModeEnabled(): Boolean {
        return commonGet { exoPlayer.shuffleModeEnabled }
    }

    fun toggleSkipSilence(enable: Boolean) {
        mainHandler.post {
            exoPlayer.skipSilenceEnabled = enable
        }
    }

    fun isSkipSilenceEnabled(): Boolean {
        return commonGet { exoPlayer.skipSilenceEnabled }
    }

    fun getPlayerSessionId(): Int {
       return commonGet { exoPlayer.audioSessionId }
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

    private fun <T> commonGet(task: () -> T): T {
        val futureTask = FutureTask(task)
        mainHandler.post(futureTask)
        return futureTask.get()
    }
}
