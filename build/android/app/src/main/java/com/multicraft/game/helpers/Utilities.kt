package com.multicraft.game.helpers

import android.annotation.SuppressLint
import android.app.Activity
import android.app.ActivityManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.view.View
import android.view.Window
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat.Type.navigationBars
import androidx.core.view.WindowInsetsCompat.Type.statusBars
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
import com.multicraft.game.MainActivity
import com.multicraft.game.R
import com.multicraft.game.helpers.ApiLevelHelper.isKitKat
import com.multicraft.game.helpers.ApiLevelHelper.isOreo
import com.multicraft.game.helpers.Constants.FILES
import com.multicraft.game.helpers.PreferencesHelper.TAG_SHORTCUT_EXIST
import java.io.File
import java.io.InputStream
import kotlin.math.roundToInt
import kotlin.system.exitProcess

@Suppress("NULLABILITY_MISMATCH_BASED_ON_JAVA_ANNOTATIONS")
object Utilities {
	@JvmStatic
	fun deleteFiles(files: List<String>, path: File) {
		for (f in files) {
			val file = File(path, f)
			if (file.exists()) file.deleteRecursively()
		}
	}

	@JvmStatic
	fun deleteFiles(files: List<File>) {
		for (file in files)
			if (file.exists()) file.deleteRecursively()
	}

	@JvmStatic
	fun getTotalMem(context: Context): Float {
		val actManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
		val memInfo = ActivityManager.MemoryInfo()
		actManager.getMemoryInfo(memInfo)
		var memory = memInfo.totalMem * 1.0f / (1024 * 1024 * 1024)
		memory = (memory * 100).roundToInt() / 100.0f
		return memory
	}

	@JvmStatic
	fun makeFullScreen(window: Window) {
		if (isKitKat) @Suppress("DEPRECATION") {
			val decor = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
					View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
					View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
			window.decorView.systemUiVisibility = decor
		} else {
			WindowCompat.setDecorFitsSystemWindows(window, false)
			WindowInsetsControllerCompat(window, window.decorView).let { controller ->
				controller.hide(statusBars() or navigationBars())
				controller.systemBarsBehavior = BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
			}
		}
	}

	@JvmStatic
	fun getIcon(activity: Activity): Drawable? {
		return try {
			activity.packageManager.getApplicationIcon(activity.packageName)
		} catch (e: PackageManager.NameNotFoundException) {
			ContextCompat.getDrawable(activity, R.mipmap.ic_launcher)
		}
	}

	@JvmStatic
	@Suppress("DEPRECATION")
	fun addShortcut(activity: AppCompatActivity) {
		if (isOreo) return
		val activityManager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
		val size = activityManager.launcherLargeIconSize
		var shortcutIconBitmap = (getIcon(activity) as BitmapDrawable).bitmap
		if (shortcutIconBitmap.width != size || shortcutIconBitmap.height != size)
			shortcutIconBitmap = Bitmap.createScaledBitmap(shortcutIconBitmap, size, size, true)
		val shortcutIntent = Intent(activity, MainActivity::class.java)
		shortcutIntent.action = Intent.ACTION_MAIN
		val addIntent = Intent()
		addIntent.putExtra("duplicate", false)
		addIntent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent)
		addIntent.putExtra(Intent.EXTRA_SHORTCUT_NAME, R.string.app_name)
		addIntent.putExtra(Intent.EXTRA_SHORTCUT_ICON, shortcutIconBitmap)
		addIntent.action = "com.android.launcher.action.INSTALL_SHORTCUT"
		activity.applicationContext.sendBroadcast(addIntent)
		// save preference
		PreferencesHelper.getInstance(activity).saveSettings(TAG_SHORTCUT_EXIST, true)
	}

	@JvmStatic
	fun getLocationByZip(context: Context, zipName: String?): String {
		return when (zipName) {
			FILES -> context.filesDir.toString()
			else -> throw IllegalArgumentException("No such zip name")
		}
	}

	@JvmStatic
	@SuppressLint("UnspecifiedImmutableFlag")
	fun finishApp(restart: Boolean, activity: Activity) {
		if (restart) {
			val intent = Intent(activity, activity::class.java)
			val mPendingIntentId = 1337
			val mgr = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
			mgr.set(
					AlarmManager.RTC, System.currentTimeMillis(), PendingIntent.getActivity(
					activity, mPendingIntentId, intent, PendingIntent.FLAG_CANCEL_CURRENT
			)
			)
		}
		exitProcess(0)
	}

	@JvmStatic
	fun File.copyInputStreamToFile(inputStream: InputStream) {
		this.outputStream().use { fileOut -> inputStream.copyTo(fileOut) }
	}
}
