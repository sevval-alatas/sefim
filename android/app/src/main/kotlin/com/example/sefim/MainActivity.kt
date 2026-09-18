package com.example.sefim

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File

class MainActivity : FlutterActivity() {
	private val channelName = "sefim/ocr"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

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
}
