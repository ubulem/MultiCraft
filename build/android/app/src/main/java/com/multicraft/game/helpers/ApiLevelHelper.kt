package com.multicraft.game.helpers

import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.KITKAT
import android.os.Build.VERSION_CODES.O

object ApiLevelHelper {
	private fun isGreaterOrEqual(versionCode: Int): Boolean {
		return SDK_INT >= versionCode
	}

	@JvmStatic
	val isKitKat: Boolean
		get() = isGreaterOrEqual(KITKAT)

	@JvmStatic
	val isOreo: Boolean
		get() = isGreaterOrEqual(O)
}
