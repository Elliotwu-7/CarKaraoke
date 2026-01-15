package com.example.carkaraoke

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.carkaraoke.audio.AudioProcessingService
import com.example.carkaraoke.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private val REQUEST_RECORD_AUDIO_PERMISSION = 200
    private var isPermissionGranted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Check and request permissions
        checkPermissions()

        // Setup UI listeners
        setupListeners()
    }

    private fun checkPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO
        )

        val permissionsToRequest = ArrayList<String>()
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
            }
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                REQUEST_RECORD_AUDIO_PERMISSION
            )
        } else {
            isPermissionGranted = true
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "麦克风权限已授予", Toast.LENGTH_SHORT).show()
                isPermissionGranted = true
            } else {
                Toast.makeText(this, "麦克风权限被拒绝，应用无法正常工作", Toast.LENGTH_SHORT).show()
                binding.btnStartKaraoke.isEnabled = false
            }
        }
    }

    private fun setupListeners() {
        binding.btnStartKaraoke.setOnClickListener {
            if (isPermissionGranted) {
                startAudioService()
            } else {
                Toast.makeText(this, "请先授予麦克风权限", Toast.LENGTH_SHORT).show()
                checkPermissions()
            }
        }

        binding.btnSettings.setOnClickListener {
            // Open settings
            Toast.makeText(this, "设置功能开发中", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startAudioService() {
        try {
            val serviceIntent = Intent(this, AudioProcessingService::class.java)
            startService(serviceIntent)
            Toast.makeText(this, "K歌会话已开始", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(this, "启动音频服务失败: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
}
