#include "main_view.h"
#include <pebble.h>
	
static AppTimer *timer;
int nochange = 0;

// BEGIN AUTO-GENERATED UI CODE; DO NOT MODIFY
static Window *s_window;
static GFont s_res_bitham_30_black;
static TextLayer *status_text;

static void initialise_ui(void) {
  s_window = window_create();
  window_set_background_color(s_window, GColorBlack);
  window_set_fullscreen(s_window, false);
  
  s_res_bitham_30_black = fonts_get_system_font(FONT_KEY_BITHAM_30_BLACK);
  // status_text
  status_text = text_layer_create(GRect(9, 61, 126, 42));
  text_layer_set_background_color(status_text, GColorBlack);
  text_layer_set_text_color(status_text, GColorWhite);
  text_layer_set_text(status_text, "READY");
  text_layer_set_text_alignment(status_text, GTextAlignmentCenter);
  text_layer_set_font(status_text, s_res_bitham_30_black);
  layer_add_child(window_get_root_layer(s_window), (Layer *)status_text);
}

static void destroy_ui(void) {
  window_destroy(s_window);
  text_layer_destroy(status_text);
}
// END AUTO-GENERATED UI CODE

static void handle_window_unload(Window* window) {
  destroy_ui();
}


static void timer_callback(void *data) {
	AccelData accel = (AccelData) { .x = 0, .y = 0, .z = 0 };
	accel_service_peek(&accel);
	
	int new_x = accel.x;
	int new_y = accel.y;
	int new_z = accel.z;
	
	int moveDirection = 0;

	if (abs(new_y) > abs(new_z) * 1.5f && abs(new_y) >= 200) {
		if (new_y > 0) {
			text_layer_set_text(status_text, "LEFT");
			moveDirection = 1;
		}
		else {
			text_layer_set_text(status_text, "RIGHT");
			moveDirection = 2;
		}
		nochange = 0;
	}
	
	else if (abs(new_y) < abs(new_z) * 1.5f && abs(new_z) >= 100) {
		if (new_z > 0) {
			text_layer_set_text(status_text, "UP");
			moveDirection = 3;
			nochange = 0;
		}
	}
	
	if (moveDirection != 0) {
		DictionaryIterator *iter;
		app_message_outbox_begin(&iter);
		Tuplet move_event = TupletInteger(0, moveDirection);
		dict_write_tuplet(iter, &move_event);
		app_message_outbox_send();
	}
	

	nochange = nochange + 1;

	
	if (nochange > 5) {
		nochange = 0;
		text_layer_set_text(status_text, "READY");
	}
		
	timer = app_timer_register(200, timer_callback, NULL);
}

void show_main_view(void) {
	initialise_ui();
	window_set_window_handlers(s_window, (WindowHandlers) {
	.unload = handle_window_unload,
	});
	window_stack_push(s_window, true);

	accel_data_service_subscribe(0, NULL);
	timer = app_timer_register(200, timer_callback, NULL);
}

void hide_main_view(void) {
	accel_data_service_unsubscribe();
	window_stack_remove(s_window, true);
}




void out_sent_handler(DictionaryIterator *sent, void *context) {
	
}


 void out_failed_handler(DictionaryIterator *failed, AppMessageResult reason, void *context) {
   // outgoing message failed
}


void in_received_handler(DictionaryIterator *received, void *context) {
	
	
}


 void in_dropped_handler(AppMessageResult reason, void *context) {
	// incoming message dropped
 }

void configure_app_message(void) {
	app_message_register_inbox_received(in_received_handler);
	app_message_register_inbox_dropped(in_dropped_handler);
	app_message_register_outbox_sent(out_sent_handler);
	app_message_register_outbox_failed(out_failed_handler);
	
	const uint32_t inbound_size = 64;
	const uint32_t outbound_size = 64;
	app_message_open(inbound_size, outbound_size);
}
