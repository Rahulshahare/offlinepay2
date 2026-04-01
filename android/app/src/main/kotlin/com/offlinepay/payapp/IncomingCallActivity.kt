package com.offlinepay.payapp

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class IncomingCallActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val callerName   = intent.getStringExtra("caller_name")   ?: "Unknown"
        val callerNumber = intent.getStringExtra("caller_number") ?: ""

        // Build simple UI programmatically
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity     = android.view.Gravity.CENTER
            setBackgroundColor(android.graphics.Color.parseColor("#1A237E"))
            setPadding(60, 100, 60, 100)
        }

        // Caller info
        val nameView = TextView(this).apply {
            text      = callerName
            textSize  = 28f
            setTextColor(android.graphics.Color.WHITE)
            gravity   = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 16) }
        }

        val numberView = TextView(this).apply {
            text      = callerNumber
            textSize  = 18f
            setTextColor(android.graphics.Color.parseColor("#B0BEC5"))
            gravity   = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 60) }
        }

        val incomingLabel = TextView(this).apply {
            text      = "Incoming Call"
            textSize  = 14f
            setTextColor(android.graphics.Color.parseColor("#80FFFFFF"))
            gravity   = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 80) }
        }

        // Button row
        val buttonRow = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            gravity     = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val rejectBtn = Button(this).apply {
            text      = "Decline"
            textSize  = 16f
            setTextColor(android.graphics.Color.WHITE)
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(android.graphics.Color.parseColor("#C62828"))
                cornerRadius = 50f
            }
            layoutParams = android.widget.LinearLayout.LayoutParams(
                0,
                160,
                1f
            ).apply { setMargins(0, 0, 24, 0) }
            setOnClickListener {
                IncomingCallManager.rejectCall()
                finish()
            }
        }

        val answerBtn = Button(this).apply {
            text      = "Answer"
            textSize  = 16f
            setTextColor(android.graphics.Color.WHITE)
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(android.graphics.Color.parseColor("#2E7D32"))
                cornerRadius = 50f
            }
            layoutParams = android.widget.LinearLayout.LayoutParams(
                0,
                160,
                1f
            ).apply { setMargins(24, 0, 0, 0) }
            setOnClickListener {
                IncomingCallManager.answerCall()
                finish()
            }
        }

        buttonRow.addView(rejectBtn)
        buttonRow.addView(answerBtn)

        layout.addView(incomingLabel)
        layout.addView(nameView)
        layout.addView(numberView)
        layout.addView(buttonRow)

        setContentView(layout)
    }
}