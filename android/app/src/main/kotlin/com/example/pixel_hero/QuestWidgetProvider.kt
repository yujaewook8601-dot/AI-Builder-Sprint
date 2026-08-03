package com.example.pixel_hero

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuestWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quest_widget).apply {
                val title = widgetData.getString("quest_title", "오늘의 퀘스트를 확인하세요!")
                val status = widgetData.getString("quest_status", "Pixel Hero")

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_status, status)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
