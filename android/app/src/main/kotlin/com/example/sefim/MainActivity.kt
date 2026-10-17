package sm.sefim

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.util.UUID

class MainActivity : FlutterActivity() {
	private val channelName = "sefim/ocr"
	private val filePickerChannelName = "sefim/file_picker"
	private val filePickerRequestCode = 0x5346
	private var pendingFilePickerResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, filePickerChannelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "pickDocument") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				if (pendingFilePickerResult != null) {
					result.error("PICKER_ACTIVE", "Belge seçici zaten açık.", null)
					return@setMethodCallHandler
				}

				pendingFilePickerResult = result
				try {
					startActivityForResult(
						Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
							addCategory(Intent.CATEGORY_OPENABLE)
							type = "*/*"
							if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
								putExtra(
									DocumentsContract.EXTRA_INITIAL_URI,
									DocumentsContract.buildDocumentUri(
										"com.android.externalstorage.documents",
										"primary:Download",
									),
								)
							}
						},
						filePickerRequestCode,
					)
				} catch (error: Exception) {
					pendingFilePickerResult = null
					result.error("PICKER_FAILED", error.message, null)
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "recognizeText") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val path = call.argument<String>("path")
				if (path.isNullOrEmpty()) {
					result.error("INVALID_PATH", "Görsel yolu bulunamadı.", null)
					return@setMethodCallHandler
				}

				val recognizer = TextRecognition.getClient(
					TextRecognizerOptions.DEFAULT_OPTIONS,
				)
				try {
					val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
					recognizer.process(image)
						.addOnSuccessListener { result.success(it.text) }
						.addOnFailureListener {
							result.error("OCR_FAILED", it.message, null)
						}
						.addOnCompleteListener { recognizer.close() }
				} catch (error: Exception) {
					recognizer.close()
					result.error("OCR_FAILED", error.message, null)
				}
			}
	}

	@Deprecated("Deprecated in Android")
	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		if (requestCode == filePickerRequestCode) {
			val result = pendingFilePickerResult
			pendingFilePickerResult = null

			if (resultCode != Activity.RESULT_OK) {
				result?.success(null)
				return
			}

			val uri = data?.data
			if (uri == null) {
				result?.error("MISSING_URI", "Seçilen belgeye erişilemedi.", null)
				return
			}

			try {
				val fileName = contentResolver.query(uri, null, null, null, null)?.use { cursor ->
					val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
					if (nameIndex >= 0 && cursor.moveToFirst()) cursor.getString(nameIndex) else null
				} ?: "secilen_dosya"
				val safeFileName = fileName
					.substringAfterLast('/')
					.substringAfterLast('\\')
					.replace(Regex("[^A-Za-z0-9._-]"), "_")
				val temporaryFile = File(cacheDir, "${UUID.randomUUID()}_$safeFileName")
				val input = contentResolver.openInputStream(uri)
					?: throw IllegalStateException("Seçilen belge okunamadı.")
				input.use { source ->
					temporaryFile.outputStream().use { target -> source.copyTo(target) }
				}
				result?.success(temporaryFile.absolutePath)
			} catch (error: Exception) {
				result?.error("DOCUMENT_READ_FAILED", error.message, null)
			}
			return
		}

		super.onActivityResult(requestCode, resultCode, data)
	}
}
