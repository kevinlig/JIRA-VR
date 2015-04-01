#include <pebble.h>
#include "main_view.h"
	
	
int main(void) {

	configure_app_message();
	
	
	show_main_view();
	
	app_event_loop();
	
}