/* -*- Mode: Vala; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 2 -*- */
/*
 * rhythmbox_remote.vala
 * Copyright (C) 2012 Adam and Monica Stark <adstark1982@yahoo.com>
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name ``Adam and Monica Stark'' nor the name of any other
 *    contributor may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 * 
 * dbus-introspect IS PROVIDED BY Adam and Monica Stark ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL Adam and Monica Stark OR ANY OTHER CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using GLib;

public class Main : GLib.Object {
	static int main (string[] args) {	
		Gtk.init(ref args);
		
		var app = new Pomeranian.App();
		
		Gtk.main() ;
		return 0;
	}
}

namespace Pomeranian {

public class Configuration : GLib.Object {
	public int pomodoro_time {get; set;}
	public int s_break_time  {get; set;}
	public int l_break_time  {get; set;}
	
	public  string INI_FILE ;
	
	private int file_exists = -1;
	
	public void commit_to_file () 
	{
		var key_file = new KeyFile ();
		key_file.set_integer ("settings","pomodoro_time",this.pomodoro_time);
		key_file.set_integer ("settings","s_break_time",this.s_break_time);
		key_file.set_integer ("settings","l_break_time",this.l_break_time);
		DirUtils.create_with_parents (Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME),493);
		
		var file = FileStream.open (this.INI_FILE, "w");
		if (file != null)
			file.puts (key_file.to_data ());
	}
	
	public Configuration.default () {
		this.INI_FILE = Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME , "config.txt",null);
		this.pomodoro_time = 25;
		this.s_break_time  = 5;
		this.l_break_time  = 15;
	}
	public Configuration () {
		this.INI_FILE = Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME , "config.txt",null);
		var key_file = new KeyFile ();

		try {
			key_file.load_from_file (this.INI_FILE, KeyFileFlags.NONE);
		} 
		catch (FileError err) {     // on error proceed to default
			if (err is FileError.NOENT) {
				file_exists = 0;
			}
			else {
				warning("Unexpected file error: %s\n", err.message);
				file_exists = -1;
			}
			this.pomodoro_time = 25;
			this.s_break_time = 5;
			this.l_break_time = 15;
			return;
		}
		catch (KeyFileError err) { // on error proceed to default 
			warning("Unexpected file error: %s\n", err.message);
			file_exists = 1;
			this.pomodoro_time = 25;
			this.s_break_time = 5;
			this.l_break_time = 15;
			return;
		}
		
		file_exists = 1;
		//pomodoro time
		try {
			this.pomodoro_time = key_file.get_integer ("settings","pomodoro_time");
		}
		catch (Error err) {
			this.pomodoro_time = 25;
		}
		
		//s break time
		try {
			this.s_break_time = key_file.get_integer ("settings","s_break_time");
		}
		catch (Error err) {
			this.s_break_time = 5;
		}
		
		//l break time
		try {
			this.l_break_time = key_file.get_integer ("settings","l_break_time");
		}
		catch (Error err) {
			this.l_break_time = 15;
		}
	}
}
public class App : GLib.Object {
	public const bool   DEBUG_STATE  = true;
	public const string PROGRAM_NAME = "Pomeranian";
	public const string VERSION = Config.VERSION;
	public       string UI_FILE ;
	
	public void debug(string format, ...) {
		if (this.DEBUG_STATE) {
			var l      = va_list();
			var output = format.vprintf(l);
			stderr.printf("%s: %s",this.PROGRAM_NAME,output);
		}
	}
	
	//{{{ Private backing variables
	private TimerUI _ui;
	private TimerUIFactory _ui_factory;
	private Gtk.StatusIcon _status_icon ;
	private Gtk.Menu _popup_menu;
	private Gtk.AboutDialog _about_dialog;
	private Configuration _app_config;
	private Gtk.Builder _builder; // The hidden nullable attribute
	private Gtk.Dialog _options_dialog;
	private SoundHandlerFactory _sound_handler_factory;
	private SoundHandler _sound_handler;
	//}}}
	
	private TimerUI get_ui () {
		if (this._ui == null) {
			this._ui = this.get_ui_factory().build(_("Gtk Interface"), this);
		}
		return this._ui;
	}
	private TimerUIFactory get_ui_factory () {
		if (this._ui_factory == null) {
			this._ui_factory = new TimerUIFactory ();
			
			this._ui_factory.register (_("Gtk Interface"), GtkTimer.FACTORY_FUNC);
		}
		return this._ui_factory;
	}
	private Gtk.StatusIcon get_status_icon () {
		if (this._status_icon == null)
		{
			var ui = this.get_ui() ;
			this._status_icon = new Gtk.StatusIcon.from_stock( Gtk.Stock.YES );
			this._status_icon.title = this.PROGRAM_NAME;
			this._status_icon.popup_menu.connect((button_id, timestamp) => {
				this.debug("Trying popup.\n");
				this.debug("Menu items should be:\n");
				this.get_popup_menu().foreach ((menu_item) =>
					{
						this.debug( "    %s\n", (menu_item as Gtk.MenuItem).label);
					});
				this.get_popup_menu().popup (null,null,null,button_id,timestamp); 
			});
			this._status_icon.activate.connect(() =>
				{
					this.get_ui().toggle_show_hide();
				});
		}
		return this._status_icon;
	}
	private Gtk.Menu get_popup_menu () throws Error {
		if (this._popup_menu == null) 
		{
			this._popup_menu      = this.get_builder().get_object("popup-menu") as Gtk.Menu;
		
			var about_menu_item   = this.get_builder().get_object("about-menu-item") as Gtk.MenuItem;
		
			about_menu_item.activate.connect ( () => 
			{
				this.get_about_dialog().run();
				this.get_about_dialog().hide ();
			});
		
			var options_menu_item = this.get_builder().get_object("preferences-menu-item") as Gtk.MenuItem;
			options_menu_item.activate.connect ( () => 
			{
				this.get_options_dialog().run();
				this.get_options_dialog().hide ();
			});
		
			var quit_menu_item    = this.get_builder().get_object("quit-menu-item") as Gtk.MenuItem;
			quit_menu_item.activate.connect (Gtk.main_quit);
		}
		return this._popup_menu;
	}
	private Gtk.AboutDialog get_about_dialog () throws Error {
		if (this._about_dialog == null)
		{
			this._about_dialog = this.get_builder().get_object ("about-dialog") as Gtk.AboutDialog;
			this._about_dialog.program_name = this.PROGRAM_NAME ;
			this._about_dialog.version = this.VERSION ;
		}
		return this._about_dialog;
	}
	public Configuration get_app_config () {
		if (this._app_config == null)
			this._app_config = new Configuration () ;
		return this._app_config;
	}
	public Gtk.Builder get_builder () throws Error {	
		if (this._builder == null) 
		{
			this._builder = new Gtk.Builder ();
			this._builder.add_from_file (this.UI_FILE);
		}
		return this._builder;
	}
	private Gtk.Dialog get_options_dialog () throws Error {
		if (this._options_dialog == null) {
			int l_break_time, s_break_time, pomodoro_time;
		
			this._options_dialog = this.get_builder().get_object ("preferences-dialog") as Gtk.Dialog;
		
			var input1       = this.get_builder().get_object ("preferences-dialog-entry1") as Gtk.Entry;
			pomodoro_time    = this.get_app_config().pomodoro_time;
		
			input1.notify["text"].connect (() =>
				{
					int64 time ;
					if (int64.try_parse (input1.text, out time))
					{
						pomodoro_time = (int) time;
					}
					else 
					{
						input1.text = pomodoro_time.to_string();
					}
				});
		
			var input2       = this.get_builder().get_object ("preferences-dialog-entry2")  as Gtk.Entry;
			s_break_time     = this.get_app_config().s_break_time;
			input2.notify["text"].connect (() =>
				{
					int64 time ;
					if (int64.try_parse (input2.text, out time))
					{
						s_break_time = (int) time;
					}
					else 
					{
						input2.text = s_break_time.to_string ();
					}
				});
		
			var input3       = this.get_builder().get_object ("preferences-dialog-entry3")  as Gtk.Entry;
			l_break_time     = this.get_app_config().l_break_time;
			input3.notify["text"].connect (() =>
				{
					int64 time ;
					if (int64.try_parse (input3.text, out time))
					{
						l_break_time = (int) time;
					}
					else 
					{
						input3.text = l_break_time.to_string ();
					}
				});
			
			this._options_dialog.response.connect ((response) =>
				{
					if (response == 2)
					{
						this.get_app_config().pomodoro_time = pomodoro_time;
						this.get_app_config().s_break_time  = s_break_time;
						this.get_app_config().l_break_time  = l_break_time;
					}
				});
			this._options_dialog.show.connect (() =>
				{
					input1.text      = this.get_app_config().pomodoro_time.to_string (); 
					input2.text      = this.get_app_config().s_break_time.to_string (); 
					input3.text      = this.get_app_config().l_break_time.to_string (); 
					this.get_app_config().commit_to_file();
				});
		}
		return this._options_dialog ;
	}
	private SoundHandlerFactory get_sound_handler_factory () {
		if (this._sound_handler_factory == null) {
			this._sound_handler_factory = new SoundHandlerFactory ();
			
			this._sound_handler_factory.register (_("Canberra"), CanberraSoundHandler.FACTORY_FUNC);
		}
		return this._sound_handler_factory;
	}
	private SoundHandler get_sound_handler () {
		if (this._sound_handler == null) {
			this._sound_handler = this.get_sound_handler_factory().build(_("Canberra"), this);
		}
		return this._sound_handler;
	}
	public App () {
	}
	construct {
		this.UI_FILE = Path.build_filename (Config.DATA_DIR,Config.PACKAGE_NAME + ".ui",null);
		this.debug (this.UI_FILE);
		/* Create the PomeranianConfig
		 */
		this.get_app_config ();
		/* Create the StatusIcon
		*/
		this.get_status_icon();	
		
		get_ui().ring.connect ((widget) =>
			{
				get_sound_handler().play (SoundBite.RING, widget);
			});
		get_ui().wind.connect ((_minutes,_seconds,widget) =>
			{
				get_sound_handler().play (SoundBite.WIND, widget);
			});
	}
}
[CCode (has_target = false)]
public delegate TimerUI UIFactoryFunc (App app) ;
public interface TimerUI : GLib.Object {
	public abstract void toggle_show_hide ();
	public signal void wind( int minutes, int seconds=0,Gtk.Widget? canberra_widget = null) ;
	public abstract void stop() ;
	public abstract bool get_time (out int minutes, out int seconds);
	public signal void ring( Gtk.Widget? canberra_widget = null);
	// public abstract static PomeranianTimerUI FACTORY_FUNC (PomeranianApp app);
}
public class TimerUIFactory : GLib.Object {
	private Gee.HashMap<string,UIFactoryFunc> instantiaters ;
	public TimerUIFactory () {
		instantiaters = new Gee.HashMap<string,UIFactoryFunc> ();
	}
	public TimerUI? build (string timer_ui_type, App app) {
		var func = this.instantiaters.get (timer_ui_type);
		if (func == null) return null;
		return func (app) ;
	}
	public void register (string timer_ui_type, UIFactoryFunc builder) {
		instantiaters.set (timer_ui_type, builder);
	}
}
public class GtkTimer : GLib.Object, TimerUI {
	enum CurrentButtonAct {
		START_POMODORO,
		START_L_BREAK,
		START_S_BREAK,
		STOP
	}
	private bool is_running = false;
	private bool is_shown = true;
	
	public int phase = 0;
	
	private weak App app;
	private CurrentButtonAct next_action = CurrentButtonAct.START_POMODORO;
	private TimeVal end_time ;
	
	
	//{{{ Hidden internal backing variables, accessed through their gettters
	private TimeoutSource _clock_tick ;
	private Gtk.Label _gtk_time_label ;
	private Gtk.Dialog _gtk_timer_dialog ;
	private Gtk.Button _gtk_timer_dialog_button;
	private Gtk.EventBox _gtk_timer_dialog_pulldown_arrow ;
	private Gtk.Menu _timer_dialog_menu;
	private Gtk.MenuItem _timer_dialog_restart ;
	private Gtk.MenuItem _timer_dialog_stop ;
	private Gtk.MenuItem _timer_dialog_short_break ;
	private Gtk.MenuItem _timer_dialog_long_break ;
	private Gtk.MenuItem _timer_dialog_quit ;
	//}}}
	
	private TimeoutSource get_clock_tick () {
		if (this._clock_tick == null) {
			this._clock_tick = new TimeoutSource.seconds (1) ;
		}
		return this._clock_tick;
	}
	private void remove_clock_tick () {
		if (this._clock_tick == null) return;
		Source.remove (this._clock_tick.get_id ());
		this._clock_tick = null;
	}
	private Gtk.Label get_gtk_time_label () {
		if (this._gtk_time_label == null) {
			this._gtk_time_label = 
				this.app.get_builder().get_object("timer-label") as Gtk.Label ;
		}
		return this._gtk_time_label ;
	}
	public Gtk.Dialog get_gtk_timer_dialog () {
		if (this._gtk_timer_dialog == null) {
			this._gtk_timer_dialog = 
				this.app.get_builder().get_object("gtk-timer-dialog") as Gtk.Dialog ;
			/*
			 * Set-up the button.
			 */
			this.get_gtk_timer_dialog_button().clicked.connect (this.run_button) ;
			this.get_gtk_timer_dialog_pulldown_arrow ();
			this._gtk_timer_dialog.realize.connect (() =>
				{
					get_gtk_timer_dialog().set_keep_above(true); 
				});
			this._gtk_timer_dialog.response.connect((response) =>
				{
					if (response == Gtk.ResponseType.DELETE_EVENT) {
						this._gtk_time_label                  = null;
						this._gtk_timer_dialog                = null;
						this._gtk_timer_dialog_button         = null;
						this._gtk_timer_dialog_pulldown_arrow = null;
						this._timer_dialog_menu               = null;
						this._timer_dialog_restart            = null;
						this._timer_dialog_stop               = null;
						this._timer_dialog_short_break        = null;
						this._timer_dialog_long_break         = null;
						this._timer_dialog_quit               = null;
						this.is_shown                         = false;
						this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"gtk-timer-dialog",null});
					}
				});
		}
		return this._gtk_timer_dialog ;
	}
	private Gtk.Button get_gtk_timer_dialog_button() {
		if (this._gtk_timer_dialog_button == null) {
			this._gtk_timer_dialog_button = 
				this.app.get_builder().get_object("gtk-timer-dialog-button") as Gtk.Button;
		}
		return this._gtk_timer_dialog_button ;
	}
	private Gtk.EventBox get_gtk_timer_dialog_pulldown_arrow () { //gtk-timer-dialog-pulldown-arrow
		if (this._gtk_timer_dialog_pulldown_arrow == null) {
			this._gtk_timer_dialog_pulldown_arrow = 
				this.app.get_builder().get_object("gtk-timer-dialog-pulldown-arrow") as Gtk.EventBox ;
			this._gtk_timer_dialog_pulldown_arrow.button_press_event.connect(
						(event) =>
						{
							this.app.debug ("Hit button press.\n");
							switch (event.button) {
								case 1:  	this.get_timer_dialog_menu().popup (
												null,
												null,
												null,
												event.button,
												event.time);
										 break;
								default: break;
							}
							return false;
						});
		}
		return this._gtk_timer_dialog_pulldown_arrow ;
	} 
	private Gtk.Menu get_timer_dialog_menu() {
		if (this._timer_dialog_menu == null) {
			this._timer_dialog_menu = 
				this.app.get_builder().get_object("timer-dialog-menu") as Gtk.Menu ;
			this.get_timer_dialog_restart().activate.connect(() =>
				{
					this.wind(this.app.get_app_config().pomodoro_time,0,get_timer_dialog_menu());
					this.get_timer_dialog_restart().label = "Restart Pomodoro";
				});
			this.get_timer_dialog_stop().activate.connect(() =>
				{
					this.stop ();
				});
			this.get_timer_dialog_short_break().activate.connect(() =>
				{
					this.phase = 1;
					this.wind(this.app.get_app_config().s_break_time,0,get_timer_dialog_menu());
					this.get_timer_dialog_restart().label = "Start Pomodoro";
				});
			this.get_timer_dialog_long_break().activate.connect(() =>
				{
					this.phase = 7;
					this.wind(this.app.get_app_config().l_break_time,0,get_timer_dialog_menu());
					this.get_timer_dialog_restart().label = "Start Pomodoro";
				});
			this.get_timer_dialog_quit().activate.connect(() =>
				{
					Gtk.main_quit() ;
				});
		}
		return this._timer_dialog_menu;
	}
	private Gtk.MenuItem get_timer_dialog_restart() {
		if (this._timer_dialog_restart == null) {
			this._timer_dialog_restart = 
				this.app.get_builder().get_object("timer-dialog-restart") as Gtk.MenuItem ;
			
		}
		return this._timer_dialog_restart;
	}
	private Gtk.MenuItem get_timer_dialog_stop() {
		if (this._timer_dialog_stop == null) {
			this._timer_dialog_stop = 
				this.app.get_builder().get_object("timer-dialog-stop") as Gtk.MenuItem ;
			
		}
		return this._timer_dialog_stop;
	}
	private Gtk.MenuItem get_timer_dialog_short_break () {
		if (this._timer_dialog_short_break == null) {
			this._timer_dialog_short_break = 
				this.app.get_builder().get_object("timer-dialog-short-break") as Gtk.MenuItem ;
			
		}
		return this._timer_dialog_short_break;
	}
	private Gtk.MenuItem get_timer_dialog_long_break () {
		if (this._timer_dialog_long_break == null) {
			this._timer_dialog_long_break = 
				this.app.get_builder().get_object("timer-dialog-long-break") as Gtk.MenuItem ;
			
		}
		return this._timer_dialog_long_break;
	}
	private Gtk.MenuItem get_timer_dialog_quit () {
		if (this._timer_dialog_quit == null) {
			this._timer_dialog_quit = 
				this.app.get_builder().get_object("timer-dialog-quit") as Gtk.MenuItem ;
			
		}
		return this._timer_dialog_quit;
	}
		
	public void run_button () {
		this.app.debug ("Reached run_button");
		switch (this.next_action) {
			case (CurrentButtonAct.START_POMODORO):
				this.wind(this.app.get_app_config().pomodoro_time,0,this.get_gtk_timer_dialog_button());
				this.get_timer_dialog_restart().label = "Restart Pomodoro";
				break;
			case (CurrentButtonAct.START_L_BREAK):
				this.wind(this.app.get_app_config().l_break_time,0,this.get_gtk_timer_dialog_button());
				this.get_timer_dialog_restart().label = "Start Pomodoro";
				break;
			case (CurrentButtonAct.START_S_BREAK):
				this.wind(this.app.get_app_config().s_break_time,0,this.get_gtk_timer_dialog_button());
				this.get_timer_dialog_restart().label = "Start Pomodoro";
				break;
			case (CurrentButtonAct.STOP):
				this.stop ();
				break;
		}
	}
	
	public GtkTimer (App app) {
		this.app = app;
		this.get_gtk_timer_dialog().show();;
		
		this.wind.connect( this.do_wind );
		this.ring.connect( this.do_ring );
	}

	public static TimerUI FACTORY_FUNC (App app) {
		var that = new GtkTimer (app) ;
		return that as TimerUI;
	}
	
	public void toggle_show_hide () {
		if (this.is_shown) {
			this.get_gtk_timer_dialog().hide();
			this.is_shown = false;
		}
		else {
			this.get_gtk_timer_dialog().show_all();
			this.is_shown = true;
		}
	}
	public void do_wind (int minutes, int seconds=0,Gtk.Widget? _ignore) {
		this.remove_clock_tick();
		this.end_time    = TimeVal ();
		this.end_time.add (( minutes*60 + seconds)*1000*1000 -1 );
		this.get_clock_tick().set_callback (this.on_clock_tick) ;
		this.get_clock_tick().attach (null);
		
		this.is_running  = true;
		this.next_action = CurrentButtonAct.STOP ;
		this.get_gtk_timer_dialog_button().label = "Stop";
		this.get_timer_dialog_stop().sensitive = true;
		this.on_clock_tick ();
	}
	public bool on_clock_tick () {
		int minutes, seconds;
		
		if (this.get_time(out minutes, out seconds)) {
			this.get_gtk_time_label().label = minutes.to_string() + ":" + ("%02d").printf (seconds);
		}
		else {
			
			this.ring (get_gtk_time_label ()); //The rest of the steps are taken care of in ring
			return false;
		}
		return true;
	}
	public void stop () {
		this.is_running = false;
		this.remove_clock_tick ();
		
		this.phase = 0;
		this.next_action = CurrentButtonAct.START_POMODORO ;
		this.get_gtk_time_label().label = "Stopped";
		this.get_gtk_timer_dialog_button().label = "Start Pomodoro";
		
		this.get_timer_dialog_restart().label = "Start Pomodoro";
		this.get_timer_dialog_stop().sensitive = false;
	}
	public void do_ring () {
		this.is_running = false;
		this.remove_clock_tick ();
		
		this.get_gtk_timer_dialog().show();
		
		this.get_gtk_time_label().label = "Stopped";
		this.get_timer_dialog_restart().label = "Start Pomodoro";
		this.get_timer_dialog_stop().sensitive = false;
		
		this.phase = (this.phase + 1)%8;
		switch (this.phase) {
			case 0:
			case 2:
			case 4:
			case 6:
				this.next_action = CurrentButtonAct.START_POMODORO ;
				this.get_gtk_timer_dialog_button().label = "Start Pomodoro";
				break;
			case 1:
			case 3:
			case 5:
				this.next_action = CurrentButtonAct.START_S_BREAK ;
				this.get_gtk_timer_dialog_button().label = "Start Short Break";
				break;
			case 7:
				this.next_action = CurrentButtonAct.START_L_BREAK ;
				this.get_gtk_timer_dialog_button().label = "Start Long Break";
				break;
		}	
	}
	public bool get_time (ref int minutes, ref int seconds) {
		if (!this.is_running) return false;
		
		var current_time  = TimeVal ();
		var secs_diff     = this.end_time.tv_sec - current_time.tv_sec ;
		var usecs_diff    = this.end_time.tv_usec - current_time.tv_usec ;
		if (secs_diff < 0 || secs_diff == 0 && usecs_diff <= 0) return false;
			
		if (usecs_diff > 0) secs_diff += 1;
		minutes  = (int) secs_diff/60;
		seconds  = (int) secs_diff % 60;
		return true;
	}
}
public enum SoundBite {
		WIND,
		RING,
		SPRING,
		TICK_TOCK
	}
[CCode (has_target = false)]
public delegate SoundHandler SoundHandlerFactoryFunc (App app) ;
public interface SoundEvent : GLib.Object {
	public abstract void cancel ();
}
public interface SoundHandler : GLib.Object {
	public abstract SoundEvent? play (SoundBite sound, Gtk.Widget? widget);
}
public class SoundHandlerFactory : GLib.Object {
	private Gee.HashMap<string,SoundHandlerFactoryFunc> instantiaters ;
	public SoundHandlerFactory() {
		instantiaters = new Gee.HashMap<string,SoundHandlerFactoryFunc> ();
	}
	public SoundHandler? build (string sound_handler_type, App app) {
		var func = this.instantiaters.get (sound_handler_type);
		if (func == null) return null;
		return func (app) ;
	}
	public void register (string sound_handler_type, SoundHandlerFactoryFunc builder) {
		instantiaters.set (sound_handler_type, builder);
	}
}
public class CanberraSoundHandler : GLib.Object, SoundHandler {
	public unowned Canberra.Context canberra_context ;
	private unowned App app;
	private uint32 current_id;
	private static string? parse_soundbite (SoundBite id) {
		switch (id) {
			case SoundBite.RING:
				return Path.build_filename(Config.SOUNDS_DIR,"ring.ogg",null);
			case SoundBite.WIND:
				return Path.build_filename(Config.SOUNDS_DIR,"wind.ogg",null);
			default:
				return null;
		}
	}
	public SoundEvent? play (SoundBite sound, Gtk.Widget? widget ) {
		var sound_name = CanberraSoundHandler.parse_soundbite (sound);
		if (sound_name != null) {
			this.app.debug ("Playing noise %s\n", sound_name);
			CanberraGtk.play_for_widget( widget, ++this.current_id, Canberra.PROP_MEDIA_FILENAME, sound_name );
			return new CanberraEvent (this.current_id, this) as SoundEvent;
		}
		return null;
	}
	public CanberraSoundHandler (App app) {
		this.app = app;
		this.canberra_context = CanberraGtk.context_get ();
	}
	public static SoundHandler FACTORY_FUNC (App app)  {
		var that = new CanberraSoundHandler (app);
		return that as SoundHandler;
	}
}
public class CanberraEvent : GLib.Object, SoundEvent {
	private uint32 _id;
	private CanberraSoundHandler handler;
	public CanberraEvent  (uint32 id, CanberraSoundHandler handler) {
		this._id = id;
		this.handler = handler;
	}
	public void cancel () {
		this.handler.canberra_context.cancel (this._id);
	}
}
}
