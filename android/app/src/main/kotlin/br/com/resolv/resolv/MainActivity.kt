package br.com.resolv.resolv

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

private const val PICK_PHOTO_REQUEST = 2042
private const val MAX_PHOTO_EDGE_PX = 1600

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingPhoto: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "resolv/storage")
        val prefs = getSharedPreferences("resolv", MODE_PRIVATE)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(prefs.getString("mural", null))
                "write" -> {
                    val json = call.arguments as? String
                    if (json == null) {
                        result.error("format", "Dados do mural inválidos.", null)
                    } else {
                        worker.execute {
                            val saved = prefs.edit().putString("mural", json).commit()
                            runOnUiThread {
                                if (saved) result.success(true)
                                else result.error("storage", "Falha ao salvar o mural.", null)
                            }
                        }
                    }
                }
                "pickPhoto" -> {
                    if (pendingPhoto != null) {
                        result.error("busy", "A seleção de imagem já está aberta.", null)
                    } else {
                        pendingPhoto = result
                        try {
                            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                type = "image/*"
                                addCategory(Intent.CATEGORY_OPENABLE)
                            }, PICK_PHOTO_REQUEST)
                        } catch (e: Exception) {
                            pendingPhoto = null
                            result.error("picker", "Não foi possível abrir as fotos.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("FlutterActivity forwards Android activity results here.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_PHOTO_REQUEST) return
        val callback = pendingPhoto ?: return
        pendingPhoto = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            callback.success(null)
            return
        }
        worker.execute {
            try {
                val bitmap = loadPreview(uri)
                val file = File.createTempFile("mural-", ".jpg", filesDir)
                try {
                    file.outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.JPEG, 84, it)) }
                } catch (failure: Exception) {
                    file.delete()
                    throw failure
                } finally {
                    bitmap.recycle()
                }
                runOnUiThread { callback.success(file.absolutePath) }
            } catch (e: Exception) {
                runOnUiThread { callback.error("image", "Não foi possível abrir a imagem.", null) }
            }
        }
    }

    private fun loadPreview(uri: Uri): Bitmap {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return ImageDecoder.decodeBitmap(ImageDecoder.createSource(contentResolver, uri)) { decoder, info, _ ->
                val width = info.size.width
                val height = info.size.height
                val scale = minOf(1.0, MAX_PHOTO_EDGE_PX.toDouble() / maxOf(width, height))
                decoder.setTargetSize(
                    maxOf(1, (width * scale).toInt()),
                    maxOf(1, (height * scale).toInt())
                )
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            }
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        val longestEdge = maxOf(bounds.outWidth, bounds.outHeight)
        while (longestEdge / sample > MAX_PHOTO_EDGE_PX) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        return requireNotNull(contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) })
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
