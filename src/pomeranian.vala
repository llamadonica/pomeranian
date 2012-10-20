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

/* The class for items that can be configured. An object is instantiated,
 * then registered with the configuration, where it is called before 
 * each commit and after the configure step.
 */

[CCode (has_target = false)]
public delegate PreferenceEnabled? PreferenceFactoryFunc () ;
public PreferenceEnabled? NO_PREFERENCES () {
	return null;
}
public abstract class PreferenceEnabled : GLib.Object {
	public abstract void configure (KeyFile key_file) ;
	public abstract void configure_from_default () ;
	public abstract void commit    (KeyFile key_file) ;
}
public class Preferences : GLib.Object {
	public int pomodoro_time {get; set;}
	public int s_break_time  {get; set;}
	public int l_break_time  {get; set;}
	
	public  string INI_FILE ;
	public bool is_configured = false;
	
	public List<PreferenceEnabled> configurators; 
	private int file_exists = -1;
	
	public void commit_to_file () {
		var key_file = new KeyFile ();
		key_file.set_integer ("settings","pomodoro_time",this.pomodoro_time);
		key_file.set_integer ("settings","s_break_time",this.s_break_time);
		key_file.set_integer ("settings","l_break_time",this.l_break_time);
		
		foreach (var configurator in this.configurators)
			configurator.commit (key_file);
		
		DirUtils.create_with_parents (Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME),493);
		
		var file = FileStream.open (this.INI_FILE, "w");
		if (file != null)
			file.puts (key_file.to_data ());
	}
	public Preferences () {
		this.INI_FILE = Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME , "config.txt",null);
		this.configurators = new List<PreferenceEnabled> ();
	}
	
	public void configure_from_default () {
		this.pomodoro_time = 25;
		this.s_break_time  = 5;
		this.l_break_time  = 15;
		foreach (var configurator in this.configurators)
			configurator.configure_from_default ();
		this.is_configured = true;
	} 
	public void configure () {
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
			this.configure_from_default ();
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
		this.is_configured = true;
	}

	public void register (PreferenceEnabled configurator) {
		this.configurators.append (configurator);
	}

}
public abstract class PreferenceDialogEnabled : GLib.Object {
	public weak PreferenceDialog preferences {get; set construct;}
	public abstract void show (Gtk.Bin container);
	public abstract void hide ();
	public abstract void try_commit ();
}
public class PreferenceDialog : GLib.Object {
	private weak App app;
	
	private Gtk.Dialog _options_dialog ;
	private Gtk.Dialog get_options_dialog () throws Error {
		if (this._options_dialog == null) {
			int l_break_time, s_break_time, pomodoro_time;
		
			this._options_dialog = this.app.get_builder().get_object ("preferences-dialog") as Gtk.Dialog;
		
			var input1       = this.app.get_builder().get_object ("preferences-dialog-entry1") as Gtk.Entry;
			pomodoro_time    = this.app.get_app_config().pomodoro_time;
		
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
		
			var input2       = this.app.get_builder().get_object ("preferences-dialog-entry2")  as Gtk.Entry;
			s_break_time     = this.app.get_app_config().s_break_time;
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
		
			var input3       = this.app.get_builder().get_object ("preferences-dialog-entry3")  as Gtk.Entry;
			l_break_time     = this.app.get_app_config().l_break_time;
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
						this.app.get_app_config().pomodoro_time = pomodoro_time;
						this.app.get_app_config().s_break_time  = s_break_time;
						this.app.get_app_config().l_break_time  = l_break_time;
					}
				});
			this._options_dialog.show.connect (() =>
				{
					input1.text      = this.app.get_app_config().pomodoro_time.to_string (); 
					input2.text      = this.app.get_app_config().s_break_time.to_string (); 
					input3.text      = this.app.get_app_config().l_break_time.to_string (); 
					this.app.get_app_config().commit_to_file();
				});
		}
		return this._options_dialog ;
	}
	public int run () {
		return this.get_options_dialog().run ();
	}
	public void hide () {
		this.get_options_dialog().hide();
	}
	public PreferenceDialog (App app) {
		this.app = app;
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
	private Preferences _app_config;
	private Gtk.Builder _builder; // The hidden nullable attribute
	private Gtk.Dialog _options_dialog;
	private SoundHandlerFactory _sound_handler_factory;
	private SoundHandler _sound_handler;
	private PreferenceDialog _preference_dialog;
	//}}}
	
	private PreferenceDialog get_preference_dialog() {
		if (this._preference_dialog == null)
			this._preference_dialog = new PreferenceDialog (this);
		return this._preference_dialog;
	}
	private TimerUI get_ui () {
		if (this._ui == null) {
			this._ui = this.get_ui_factory().build(_("Tomato Interface"), this);
		}
		return this._ui;
	}
	private TimerUIFactory get_ui_factory () {
		if (this._ui_factory == null) {
			this._ui_factory = new TimerUIFactory (this.get_app_config());
			
			this._ui_factory.register (_("Gtk Interface"), GtkTimer.FACTORY_FUNC, NO_PREFERENCES);
			this._ui_factory.register (_("Tomato Interface"), VisualTimer.FACTORY_FUNC, NO_PREFERENCES);
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
				this.get_preference_dialog().run();
				this.get_preference_dialog().hide ();
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
	public Preferences get_app_config () {
		if (this._app_config == null) {
			this._app_config = new Preferences () ;
		}
		return this._app_config;
	}
	public Preferences configure_app_preferences () {
		this.get_ui_factory();
		this.get_sound_handler_factory();
		
		this.get_app_config().configure();
		return this.get_app_config();
	}
	public Gtk.Builder get_builder () throws Error {	
		if (this._builder == null) 
		{
			this._builder = new Gtk.Builder ();
			this._builder.add_from_file (this.UI_FILE);
		}
		return this._builder;
	}
	private SoundHandlerFactory get_sound_handler_factory () {
		if (this._sound_handler_factory == null) {
			this._sound_handler_factory = new SoundHandlerFactory (this.get_app_config());
			
			this._sound_handler_factory.register (_("Canberra"), CanberraSoundHandler.FACTORY_FUNC, NO_PREFERENCES);
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
		this.UI_FILE = Path.build_filename (Config.UIDIR,Config.PACKAGE_NAME + ".ui",null);
		this.debug (this.UI_FILE);
		/* Create the PomeranianConfig
		 */
		this.configure_app_preferences ();
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
public delegate TimerUI UIFactoryFunc (App app, PreferenceEnabled? pref) ;

public class TimerUIFactory : GLib.Object {
	private weak Preferences preferences;
	private Gee.HashMap<string,UIFactoryFunc> instantiaters ;
	private Gee.HashMap<string,unowned PreferenceEnabled> instantiaters_preferences; 
	public TimerUIFactory (Preferences preferences) {
		this.preferences = preferences;
		instantiaters = new Gee.HashMap<string,UIFactoryFunc> ();
		instantiaters_preferences = new Gee.HashMap<string,PreferenceEnabled> ();
	}
	public TimerUI? build (string timer_ui_type, App app) {
		var preferences = this.instantiaters_preferences.get (timer_ui_type);
		var func = this.instantiaters.get (timer_ui_type);
		if (func == null) return null;
		return func (app,preferences) ;
	}
	public void register (string timer_ui_type, UIFactoryFunc builder, PreferenceFactoryFunc pref_builder) {
		instantiaters.set       (timer_ui_type, builder);
		
		assert (!this.preferences.is_configured);
		
		var preferences = pref_builder ();
		if (preferences != null) {
			this.preferences.register(preferences);
			this.instantiaters_preferences.set (timer_ui_type, preferences);
		}
	}
}
public abstract class TimerUI : Object {
	public PreferenceDialogEnabled? preference_dialog {get; private set;}
	private TimeVal end_time;
	private TimeoutSource _clock_tick ;
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
	
	public bool is_running {get; set;}
	
	public abstract void toggle_show_hide ();
	public abstract void destroy ();
		
	public virtual signal void wind (int minutes, int seconds=0,Gtk.Widget? canberra_widget = null) {
		this.remove_clock_tick();
		this.end_time    = TimeVal ();
		this.end_time.add (( minutes*60 + seconds)*1000*1000 -1 );
		this.get_clock_tick().set_callback (this.on_clock_tick) ;
		this.get_clock_tick().attach (null);
		
		this.is_running  = true;
	}	
	public virtual signal void ring (Gtk.Widget? canberra_widget = null) {
		this.is_running = false;
		this.remove_clock_tick ();
	}
	public virtual signal void cancel () {
		this.is_running = false;
		this.remove_clock_tick ();
	}
	
	construct {	
		this.is_running = false;
	}
	
	public abstract void update_time_display (int minutes, int seconds);
	public abstract Gtk.Widget? ringing_widget ();
	
	public bool on_clock_tick () {
		int minutes, seconds;
		
		if (this.get_time(out minutes, out seconds)) {
			this.update_time_display (minutes, seconds);
			//this.get_gtk_time_label().label = minutes.to_string() + ":" + ("%02d").printf (seconds);
		}
		else {
			this.ring (this.ringing_widget ());
			// this.ring (get_gtk_time_label ()); //The rest of the steps are taken care of in ring
			return false;
		}
		return true;
	}
	public bool get_time (out int minutes, out int seconds) {
		minutes = 0; seconds = 0;
		
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
	//public abstract static TimerUI FACTORY_FUNC (App app);
	~TimerUI () {
		this.destroy ();
	}
}
public class GtkTimer : TimerUI {
	enum CurrentButtonAct {
		START_POMODORO,
		START_L_BREAK,
		START_S_BREAK,
		STOP
	}	
	public int phase = 0;
	private bool is_shown = true;
	
	private weak App app;
	private CurrentButtonAct next_action = CurrentButtonAct.START_POMODORO;	
	
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
					this.cancel ();
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
				this.cancel ();
				break;
		}
	}
	
	public GtkTimer (App app) {
		this.app = app;
		this.get_gtk_timer_dialog().show();;
	}
	construct {
		this.wind.connect_after (this.do_wind);
		this.ring.connect_after (this.do_ring);
		this.cancel.connect_after (this.do_cancel);
	}

	public static TimerUI FACTORY_FUNC (App app) {
		var that = new GtkTimer (app) ;
		return that as TimerUI;
	}
	
	public override void toggle_show_hide () {
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
		this.next_action = CurrentButtonAct.STOP ;
		this.get_gtk_timer_dialog_button().label = "Stop";
		this.get_timer_dialog_stop().sensitive = true;
		this.on_clock_tick ();
	}
	public void do_ring () {
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
				this.next_action = CurrentButtonAct.START_S_BREAK ;
				this.get_gtk_timer_dialog_button().label = "¹Start Short Break";
				break;
			case 3:
				this.next_action = CurrentButtonAct.START_S_BREAK ;
				this.get_gtk_timer_dialog_button().label = "²Start Short Break";
				break;
			case 5:
				this.next_action = CurrentButtonAct.START_S_BREAK ;
				this.get_gtk_timer_dialog_button().label = "³Start Short Break";
				break;
			case 7:
				this.next_action = CurrentButtonAct.START_L_BREAK ;
				this.get_gtk_timer_dialog_button().label = "⁴Start Long Break";
				break;
		}
	}
	public void do_cancel () {
		this.phase = 0;
		this.next_action = CurrentButtonAct.START_POMODORO ;
		this.get_gtk_time_label().label = "Stopped";
		this.get_gtk_timer_dialog_button().label = "Start Pomodoro";
		
		this.get_timer_dialog_restart().label = "Start Pomodoro";
		this.get_timer_dialog_stop().sensitive = false;
	}

	public override void update_time_display (int minutes, int seconds) {
		this.get_gtk_time_label().label = minutes.to_string() + ":" + ("%02d").printf (seconds);
	}
	public override Gtk.Widget? ringing_widget () {
		return get_gtk_time_label ();
	}
	public override void destroy () {
		if (this.app.ref_count == 0 || this._gtk_timer_dialog != null) 
			return;
		this._gtk_timer_dialog.destroy ();
		this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"gtk-timer-dialog",null});
	}
}
public class VisualTimer : TimerUI {
	//{{{ Hidden internal backing variables, accessed through their gettters
	private Gtk.Window _pom_gtk_window ;
	private Gtk.DrawingArea _pom_gtk_surface ;
	private Cairo.ImageSurface _current_frame;
	private string anidir;
	//}}}
	
	private int current_frame = 0;
	const int seconds_per_frame = 10;
	private bool is_shown = true;
	
	public Gtk.Window get_pom_gtk_window () {
		if (this._pom_gtk_window == null) {
			this._pom_gtk_window = 
				this.app.get_builder().get_object("pom-gtk-window") as Gtk.Window ;
			this._pom_gtk_window.set_visual(this._pom_gtk_window.get_screen().get_rgba_visual());
			get_pom_gtk_surface().draw.connect( this.redraw_surface );
		}
		return this._pom_gtk_window;
	}
	private Gtk.DrawingArea get_pom_gtk_surface  () {
		if (this._pom_gtk_surface == null) {
			this._pom_gtk_surface = 
				this.app.get_builder().get_object("pom-gtk-surface") as Gtk.DrawingArea ;
		}
		return this._pom_gtk_surface;
	}
	private Cairo.ImageSurface get_current_frame () {
		var format = "%04d.png";
		if ( this.frame_should_be () != current_frame
		     || this._current_frame == null ) {
			var file_name = Path.build_filename(this.anidir,format.printf(this.current_frame = this.frame_should_be ()));
			this._current_frame = new Cairo.ImageSurface.from_png (file_name);
		}
		return this._current_frame;
	}
	public bool redraw_surface (Cairo.Context cr) {
		cr.scale(0.5,0.5);
		cr.set_source_surface (this.get_current_frame(),0,0);
		cr.set_operator(Cairo.Operator.SOURCE);
		cr.paint ();
		return true;
	}
	private int frame_should_be () {
		int minutes, seconds;
		this.get_time (out minutes, out seconds);
		return (minutes*60 + seconds)/this.seconds_per_frame ;
	}
	private weak App app;
	public VisualTimer (App app) {
		this.app = app;
		this.anidir = Config.ANIDIR;
		this.get_pom_gtk_window().show();
	}
	public override void update_time_display (int minutes, int seconds) {
		if (this.frame_should_be () != current_frame) {
			get_pom_gtk_surface().queue_draw ();
		}
	}
	public override void toggle_show_hide () {
		if (this.is_shown) {
			this.get_pom_gtk_window().hide();
			this.is_shown = false;
		}
		else {
			this.get_pom_gtk_window().show_all();
			this.is_shown = true;
		}
	}
	public override Gtk.Widget? ringing_widget () {
		return this.get_pom_gtk_surface ();
	}
	public override void destroy () {
		if (this.app.ref_count == 0 || this._pom_gtk_window != null) 
			return;
		this._pom_gtk_window .destroy ();
		this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"pom-gtk-window",null});
	}
	public static TimerUI FACTORY_FUNC (App app) {
		var that = new VisualTimer (app) ;
		return that as TimerUI;
	}
}

public enum SoundBite {
		WIND,
		RING,
		SPRING,
		TICK_TOCK
	}
[CCode (has_target = false)]
public delegate SoundHandler SoundHandlerFactoryFunc (App app, PreferenceEnabled? pref) ;
public abstract class SoundEvent : GLib.Object {
	public abstract void cancel ();
}
public class SoundHandlerFactory : GLib.Object {
	private weak Preferences preferences;
	private Gee.HashMap<string,SoundHandlerFactoryFunc> instantiaters ;
	private Gee.HashMap<string,unowned PreferenceEnabled> instantiaters_preferences; 
	public SoundHandlerFactory(Preferences preferences) {
		this.preferences = preferences;
		instantiaters = new Gee.HashMap<string,SoundHandlerFactoryFunc> ();
		instantiaters_preferences = new  Gee.HashMap<string,unowned PreferenceEnabled> ();
	}
	public SoundHandler? build (string sound_handler_type, App app) {
		var preferences = this.instantiaters_preferences.get (sound_handler_type);
		var func = this.instantiaters.get (sound_handler_type);
		if (func == null) return null;
		return func (app,preferences) ;
	}
	public void register (string sound_handler_type, SoundHandlerFactoryFunc builder, PreferenceFactoryFunc pref_builder) {
		instantiaters.set (sound_handler_type, builder);
		
		assert (!this.preferences.is_configured);
		
		var preferences = pref_builder ();
		if (preferences != null) {
			this.preferences.register(preferences);
			this.instantiaters_preferences.set (sound_handler_type, preferences);
		}
	}
}
public abstract class SoundHandler : GLib.Object {
	public abstract SoundEvent? play (SoundBite sound, Gtk.Widget? widget);
	public abstract void destroy ();
	~SoumdHandler () {
		this.destroy ();
	}
}
public class CanberraSoundHandler : SoundHandler {
	public unowned Canberra.Context canberra_context ;
	private unowned App app;
	private uint32 current_id;
	private static string? parse_soundbite (SoundBite id) {
		switch (id) {
			case SoundBite.RING:
				return Path.build_filename(Config.SOUNDSDIR,"ring.ogg",null);
			case SoundBite.WIND:
				return Path.build_filename(Config.SOUNDSDIR,"wind.ogg",null);
			default:
				return null;
		}
	}
	public override SoundEvent? play (SoundBite sound, Gtk.Widget? widget ) {
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
	public override void destroy () {return;}
}
public class CanberraEvent :  SoundEvent {
	private uint32 _id;
	private weak CanberraSoundHandler handler;
	public CanberraEvent  (uint32 id, CanberraSoundHandler handler) {
		this._id = id;
		this.handler = handler;
	}
	public override void cancel () {
		this.handler.canberra_context.cancel (this._id);
	}
}
}
