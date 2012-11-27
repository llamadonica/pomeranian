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
		Gst.init(ref args);
		
		var app = new Pomeranian.App();
		
		Gtk.main() ;
		return 0;
	}
}

namespace Pomeranian {

public class DisconnectionManager : Object {
	public weak Object object     {get; set;}
	public      ulong  handler_id {get; set;}
	public DisconnectionManager () {;}
	public new void disconnect () {
		if (object==null) return;
		
		object.disconnect (handler_id);
		object = null;
		handler_id = 0;
	}
}

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
	
	public abstract signal void has_changed ();
}
public class Preferences : GLib.Object {
	public int pomodoro_time {get; set;}
	public int s_break_time  {get; set;}
	public int l_break_time  {get; set;}
	public string ui_view {get;set;}
	
	public  string INI_FILE ;
	public bool is_configured = false;
	
	private bool should_commit = false;
	
	public List<PreferenceEnabled> configurators; 
	private int file_exists = -1;
	
	public Preferences () {
		this.INI_FILE = Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME , "config.txt",null);
		this.configurators = new List<PreferenceEnabled> ();
		
	}
	construct {
	}
	~Preferences () {
		this.commit_to_file();
	}
	
	private void commit_to_file () {
		if (!should_commit) return;
		
		var key_file = new KeyFile ();
		key_file.set_integer ("settings","pomodoro_time",this.pomodoro_time);
		key_file.set_integer ("settings","s_break_time",this.s_break_time);
		key_file.set_integer ("settings","l_break_time",this.l_break_time);
		key_file.set_string  ("settings", "ui_view",this.ui_view);
		
		foreach (var configurator in this.configurators)
			configurator.commit (key_file);
		
		DirUtils.create_with_parents (Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE_NAME),493);
		
		var file = FileStream.open (this.INI_FILE, "w");
		if (file != null)
			file.puts (key_file.to_data ());
	}
	public void configure_from_default () {
		this.pomodoro_time = 25;
		this.s_break_time  = 5;
		this.l_break_time  = 15;
		this.ui_view = "Tomato Interface";
		foreach (var configurator in this.configurators)
			configurator.configure_from_default ();
			
		this.notify["pomodoro_time"].connect(() =>
			{ this.should_commit = true; });
		this.notify["s_break_time"].connect(() =>
			{ this.should_commit = true; });
		this.notify["l_break_time"].connect(() =>
			{ this.should_commit = true; });
		this.notify["ui_view"].connect(() =>
			{ this.should_commit = true; });
		this.is_configured = true;
		this.should_commit = true;
	} 
	public void configure () {
		var key_file = new KeyFile ();

		try {
			key_file.load_from_file (this.INI_FILE, KeyFileFlags.NONE);
		} 
		catch (FileError err) {     // on error proceed to default
			if (err is FileError.NOENT) {
				file_exists = 0;
				this.should_commit = true;
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
			this.configure_from_default ();
			return;
		}
		
		file_exists = 1;
		//pomodoro time
		try {
			this.pomodoro_time = key_file.get_integer ("settings","pomodoro_time");
		}
		catch (KeyFileError err) {
			this.pomodoro_time = 25; this.should_commit = true;
		}
		
		//s break time
		try {
			this.s_break_time = key_file.get_integer ("settings","s_break_time");
		}
		catch (KeyFileError err) {
			this.s_break_time = 5; this.should_commit = true;
		}
		
		//l break time
		try {
			this.l_break_time = key_file.get_integer ("settings","l_break_time");
		}
		catch (KeyFileError err) {
			this.l_break_time = 15; this.should_commit = true;
		}
		
		//timer_ui
		try {
			this.ui_view = key_file.get_string ("settings","ui_view");
		}
		catch (KeyFileError err) {
			this.ui_view  = "Tomato Interface"; this.should_commit = true;
		}
		
		foreach (var configurator in this.configurators)
			configurator.configure (key_file);
		
		this.notify.connect(() => { 
			stderr.printf ("Preferences says \"should_commit=true\".\n");
			this.should_commit = true; });
	}
	public void register (PreferenceEnabled configurator) {
		this.configurators.append (configurator);
		configurator.has_changed.connect(() =>
			{this.should_commit = true;});
	}

}

public abstract class PreferenceDialogEnabled : GLib.Object {
	public abstract void instantiate (Gtk.Bin container);
	public abstract void show ();
	public abstract void hide ();
	public abstract void try_commit ();
	public abstract void try_uncommit ();
}
public class PreferenceDialog : GLib.Object {
	private weak App app;
	private PreferenceDialogEnabled? ui_sub_dialog;
	private PreferenceDialogEnabled? sound_sub_dialog;
	private Gtk.Expander _ui_expander;
	private Gtk.Expander _audio_expander;
	
	private string previous_ui_view;
	
	private Gtk.Dialog _options_dialog ;
	private Gtk.Expander get_ui_expander () {
		if (this._ui_expander == null) {
			this._ui_expander = this.app.get_builder().get_object ("preferences-dialog-ui-expander") as Gtk.Expander;
		}
		return this._ui_expander;
	}
	private Gtk.Expander get_audio_expander () {
		if (this._ui_expander == null) {
			this._ui_expander = this.app.get_builder().get_object ("preferences-dialog-ui-expander") as Gtk.Expander;
		}
		return this._ui_expander;
	}
	
	private Gtk.Dialog get_options_dialog () throws Error {
		if (this._options_dialog == null) {
			int l_break_time, s_break_time, pomodoro_time;
			string ui_view;
		
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
			
			var ui_menu      = this.app.get_builder().get_object ("preference-dialog-interface-selector") as Gtk.ComboBoxText ;
			this.previous_ui_view = this.app.get_app_config().ui_view ;
			bool valid_view  = false;
			
			var key_iterator = this.app.get_ui_factory().instantiaters.map_iterator();
			if (key_iterator.first()) {
				do {
					ui_menu.append(key_iterator.get_key(), key_iterator.get_key());
					if (this.previous_ui_view == key_iterator.get_key())
						valid_view = true;
				} while (key_iterator.next());
			}
			if (valid_view) {
				ui_menu.set_active_id (this.previous_ui_view);
			} else {
				ui_menu.set_active_id ("Tomato Interface");
			}
			ui_menu.changed.connect(() =>
				{
					this.app.debug("Changed UI interface to: %s\n", ui_menu.get_active_id());
					if (this.ui_sub_dialog != null)
						this.ui_sub_dialog .hide();
					
					this.app.get_app_config().ui_view = ui_menu.get_active_id() ;
					this.ui_sub_dialog = this.app.get_ui().preference_dialog ;
					if (this.ui_sub_dialog != null)
					{
						this.get_ui_expander().sensitive = true;
						this.ui_sub_dialog.instantiate(this.get_ui_expander());
						this.ui_sub_dialog.show();
					}
					else
					{
						this.get_ui_expander().expanded  = false;
						this.get_ui_expander().sensitive = false;
					}
					
					this.app.debug("Finished interface change: %s\n", ui_menu.get_active_id());
				});
			
			this.ui_sub_dialog = this.app.get_ui().preference_dialog ;
			if (this.ui_sub_dialog != null)
			{
				this.get_ui_expander().sensitive = true;
				this.ui_sub_dialog.instantiate (this.get_ui_expander());
			}
			else
			{
				this.get_ui_expander().expanded  = false;
				this.get_ui_expander().sensitive = false;
			}
			this._options_dialog.response.connect ((response) =>
				{
					if (response == 2)
					{
						this.app.get_app_config().pomodoro_time = pomodoro_time;
						this.app.get_app_config().s_break_time  = s_break_time;
						this.app.get_app_config().l_break_time  = l_break_time;
						this.previous_ui_view = this.app.get_app_config().ui_view;
						
						if (this.ui_sub_dialog != null) {
							this.ui_sub_dialog.try_commit();
						}
					}
					else
					{
						this.app.get_app_config().ui_view = this.previous_ui_view;
						if (this.ui_sub_dialog != null) {
							this.ui_sub_dialog.try_uncommit();
						}
					}
				});
			this._options_dialog.show.connect (() =>
				{
					input1.text      = this.app.get_app_config().pomodoro_time.to_string (); 
					input2.text      = this.app.get_app_config().s_break_time.to_string (); 
					input3.text      = this.app.get_app_config().l_break_time.to_string (); 
				});
			
			this.sound_sub_dialog = this.app.get_sound_handler().preference_dialog;
			if (this.sound_sub_dialog != null) 
			{
				this.get_audio_expander().sensitive = true;
				this.sound_sub_dialog.instantiate (this.get_audio_expander());
			} 
			else
			{
				this.get_audio_expander().expanded  = false;
				this.get_audio_expander().sensitive = false;
			}
			
		}
		return this._options_dialog ;
	}
	public int run () {
		this.get_options_dialog() ; // This should be done a little better.
		if (this.ui_sub_dialog != null) {
			this.ui_sub_dialog.show ();
		}
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
	private SoundLoop?  sound_loop;
	
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
	public TimerUI get_ui () {
		if (this._ui == null) {
			this._ui = this.get_ui_factory().build(this.get_app_config().ui_view, this);
		}
		return this._ui;
	}
	public TimerUIFactory get_ui_factory () {
		if (this._ui_factory == null) {
			this._ui_factory = new TimerUIFactory (this.get_app_config());
			
			this._ui_factory.register (_("Gtk Interface"), GtkTimer.FACTORY_FUNC, NO_PREFERENCES);
			this._ui_factory.register (_("Tomato Interface"), VisualTimer.FACTORY_FUNC, VisualTimerPreferences.FACTORY_FUNC);
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
			quit_menu_item.activate.connect (() =>
				{	if (this._ui != null)
						this._ui.destroy();
					Gtk.main_quit();
				}
			);
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
		this.get_app_config().notify["ui-view"].connect(() =>
				{
					int minutes, seconds;
					var is_running = this.get_ui().get_time(out minutes, out seconds);
					this.get_ui().destroy();
					
					this._ui = null;
					var ui = this.get_ui();
					if (is_running)
						ui.wind (minutes, seconds);
					get_ui().ring.connect ((widget) =>
						{
							get_sound_handler().play (SoundBite.RING, widget);
							this.sound_loop.cancel ();
						});
					get_ui().cancel.connect(() => {
							this.sound_loop.cancel ();
						});
					get_ui().wind.connect ((_minutes,_seconds,widget) =>
						{
							get_sound_handler().play (SoundBite.WIND, widget);
							this.sound_loop = get_sound_handler().loop(SoundBite.TICK_TOCK, null);
						});
				});
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
			
			this._sound_handler_factory.register (_("Canberra"),  CanberraSoundHandler.FACTORY_FUNC, NO_PREFERENCES);
			this._sound_handler_factory.register (_("GStreamer"), GStreamerSoundHandler.FACTORY_FUNC, NO_PREFERENCES);
		}
		return this._sound_handler_factory;
	}
	public SoundHandler get_sound_handler () {
		if (this._sound_handler == null) {
			this._sound_handler = this.get_sound_handler_factory().build(_("GStreamer"), this);
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
				this.sound_loop.cancel ();
			});
		get_ui().cancel.connect(() => {
				this.sound_loop.cancel ();
			});
		get_ui().wind.connect ((_minutes,_seconds,widget) =>
			{
				get_sound_handler().play (SoundBite.WIND, widget);
				this.sound_loop = get_sound_handler().loop(SoundBite.TICK_TOCK, null);
			});
	}
}

[CCode (has_target = false)]
public delegate TimerUI UIFactoryFunc (App app, PreferenceEnabled? pref) ;

public class TimerUIFactory : GLib.Object {
	private weak Preferences preferences;
	public  Gee.HashMap<string,UIFactoryFunc> instantiaters ;
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
	public PreferenceDialogEnabled? preference_dialog {get; protected set;}
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
		if (this.app.ref_count == 0 || this._gtk_timer_dialog == null) 
			return;
		this._gtk_timer_dialog.destroy ();
		this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"gtk-timer-dialog",null});
	}
}

public class VisualTimer : TimerUI {
	
	enum Phase {
		POMODORO_1,
		BREAK_1,
		POMODORO_2,
		BREAK_2,
		POMODORO_3,
		BREAK_3,
		POMODORO_4,
		BREAK_4;
	}
	//{{{ Hidden internal backing variables, accessed through their gettters
	private Gtk.Window _pom_gtk_window ;
	private Gtk.DrawingArea _pom_gtk_surface ;
	private Cairo.ImageSurface _current_frame;
	private Gtk.Menu _timer_dialog_menu;
	private Gtk.MenuItem _timer_dialog_restart ;
	private Gtk.MenuItem _timer_dialog_stop ;
	private Gtk.MenuItem _timer_dialog_short_break ;
	private Gtk.MenuItem _timer_dialog_long_break ;
	private Gtk.MenuItem _timer_dialog_quit ;
	private string anidir;
	
	//}}}
	
	public VisualTimerPreferences preferences;
	
	private int current_frame = 0;
	const int seconds_per_frame = 10;
	private bool is_shown = true;
	private double scale_factor;
	private bool is_winding_up = false;
	
	private bool  mouse_is_down = false;
	
	private Phase current_phase;
	
	const string FONT_DESCRIPTION = "Sans Bold 20";
	const long   WIND_UP_DURATION = 500000;
	
	private TimeVal start_time;
	private long    final_wind_up_frame;
	private TimeoutSource wind_up_handler;
	
	
	public Gtk.Window get_pom_gtk_window () {
		if (this._pom_gtk_window == null) {
			this._pom_gtk_window = 
				this.app.get_builder().get_object("pom-gtk-window") as Gtk.Window ;
			this._pom_gtk_window.set_visual(this._pom_gtk_window.get_screen().get_rgba_visual());
			
			if (this.preferences.is_positioned) {
				this._pom_gtk_window.move(this.preferences.pos_x,this.preferences.pos_y);
			}
			
			this._pom_gtk_window.set_opacity (this.preferences.opacity/100);
			var opacity_handler = this.preferences.notify["opacity"].connect(() => {
					this.get_pom_gtk_window().set_opacity (this.preferences.opacity/100);
				});
			this._pom_gtk_window.realize.connect_after(() => {
					Cairo.RectangleInt[] input_region_temp = new Cairo.RectangleInt[input_region.length];
					int j = 0;
					for (int i = 0; i<input_region.length; i++) {
						input_region_temp[j].x = input_region[i].x*this.preferences.size / 240;
						input_region_temp[j].y = input_region[i].y*this.preferences.size / 240;
						input_region_temp[j].width = (input_region[i].x + input_region[i].width)*this.preferences.size / 240 - input_region_temp[j].x;
						input_region_temp[j].height = (input_region[i].y + input_region[i].height)*this.preferences.size / 240 - input_region_temp[j].y;
						if (input_region_temp[j].width > 0 && input_region_temp[j].height > 0) j++;
						this.app.debug("\t{%d,%d,%d,%d},\n", input_region_temp[j].x,input_region_temp[j].y,input_region_temp[j].width,input_region_temp[j].height);
					}
					Cairo.RectangleInt[] input_region_new = new Cairo.RectangleInt[j + 1];
					for (int i = 0; i<=j; i++) 
						input_region_new[i] = input_region_temp[i];
					
					this.get_pom_gtk_window().set_keep_above(true); 
					Cairo.Region region   = new Cairo.Region.rectangles(input_region_new);
					this.get_pom_gtk_window().get_window().input_shape_combine_region(region,0,0);
					this.app.debug("Input shape combined. %d\n", input_region_temp.length);
				});
			this._pom_gtk_window.destroy.connect(() => {
					this.preferences.disconnect (opacity_handler);
				});
			this._pom_gtk_window.delete_event.connect((_) => {
					int root_x, root_y;
					this._pom_gtk_window.get_position (out root_x, out root_y);
					this.preferences.position (root_x,root_y);
					
					this._pom_gtk_window                 = null;
					this._pom_gtk_surface                = null;
					this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"pom-gtk-window",null});
					
					this.is_shown = false;
					return false;
				});
				
			this.get_pom_gtk_surface().set_size_request (this.preferences.size, this.preferences.size);
			this.scale_factor = ((double) this.preferences.size)/240 ;
			var size_handler = this.preferences.notify["size"].connect(() => {
					this.get_pom_gtk_surface().set_size_request (this.preferences.size, this.preferences.size);
					this.scale_factor = ((double) this.preferences.size)/240 ;
					this.get_pom_gtk_surface().queue_draw();
					Cairo.RectangleInt[] input_region_temp = new Cairo.RectangleInt[input_region.length];
					int j = 0;
					for (int i = 0; i<input_region.length; i++) {
						input_region_temp[j].x = input_region[i].x*this.preferences.size / 240;
						input_region_temp[j].y = input_region[i].y*this.preferences.size / 240;
						input_region_temp[j].width = (input_region[i].x + input_region[i].width)*this.preferences.size / 240 - input_region_temp[j].x;
						input_region_temp[j].height = (input_region[i].y + input_region[i].height)*this.preferences.size / 240 - input_region_temp[j].y;
						if (input_region_temp[j].width > 0 && input_region_temp[j].height > 0) j++;
						this.app.debug("\t{%d,%d,%d,%d},\n", input_region_temp[j].x,input_region_temp[j].y,input_region_temp[j].width,input_region_temp[j].height);
					}
					Cairo.RectangleInt[] input_region_new = new Cairo.RectangleInt[j + 1];
					for (int i = 0; i<=j; i++) 
						input_region_new[i] = input_region_temp[i];
					
					Cairo.Region region   = new Cairo.Region.rectangles(input_region_new);
					this.get_pom_gtk_window().get_window().input_shape_combine_region(region,0,0);
					this.app.debug("Input shape combined. %d\n", input_region_temp.length);
				});
			this.get_pom_gtk_surface().destroy.connect(() => {
					this.preferences.disconnect (size_handler);
				});
			get_pom_gtk_surface().draw.connect( this.redraw_surface );
			
			get_pom_gtk_surface().button_press_event.connect ((event) => {
					if (event.type != Gdk.EventType.BUTTON_PRESS) return false;
					switch (event.button) {
						case 3:
							this.get_timer_dialog_menu().popup (
								null,
								null,
								null,
								event.button,
								event.time);
							break;
						default:
							var release      = new DisconnectionManager ();
							var leave        = new DisconnectionManager ();
							var double_click = new DisconnectionManager ();
							
							release.object = 
							leave.object   =
							double_click.object =
								get_pom_gtk_surface();
							release.handler_id = get_pom_gtk_surface().button_release_event.connect((event) => {
									this.run_button();
									release.disconnect();
									leave.disconnect();
									double_click.disconnect();
									return true;
								});
							leave.handler_id   = get_pom_gtk_surface().leave_notify_event.connect ((event) => {
									release.disconnect();
									leave.disconnect();
									double_click.disconnect();
									return false;
								});
							double_click.handler_id = get_pom_gtk_surface().button_press_event.connect ((event) => {
									if (event.type == Gdk.EventType.2BUTTON_PRESS || 
										event.type == Gdk.EventType.3BUTTON_PRESS) {
										release.disconnect();
										leave.disconnect();
										double_click.disconnect();
										return true;
									}
									return false;
								});
							break;
					}
					return true;
				});
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
	private Gtk.Menu get_timer_dialog_menu() {
		if (this._timer_dialog_menu == null) {
			this._timer_dialog_menu = 
				this.app.get_builder().get_object("timer-dialog-menu") as Gtk.Menu ;
			this.get_timer_dialog_restart().activate.connect(() =>
				{
					this.current_phase = Phase.POMODORO_1;
					this.wind(this.app.get_app_config().pomodoro_time,0,get_timer_dialog_menu());
					this.get_timer_dialog_restart().label = "Restart Pomodoro";
				});
			this.get_timer_dialog_stop().activate.connect(() =>
				{
					this.cancel ();
				});
			this.get_timer_dialog_short_break().activate.connect(() =>
				{
					this.current_phase = Phase.BREAK_1;
					this.wind(this.app.get_app_config().s_break_time,0,get_timer_dialog_menu());
					this.get_timer_dialog_restart().label = "Start Pomodoro";
				});
			this.get_timer_dialog_long_break().activate.connect(() =>
				{
					this.current_phase = Phase.BREAK_4;
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
	
	public bool redraw_surface (Cairo.Context cr) {
		cr.scale(this.scale_factor,this.scale_factor);
		cr.set_source_surface (this.get_current_frame(),0,0);
		cr.set_operator(Cairo.Operator.SOURCE);
		
		cr.paint ();
		
		if (!this.is_running) {
			cr.set_source_rgba (1,1,1,0.8);
			var    layout = Pango.cairo_create_layout (cr);
			string message ;
			switch (this.current_phase) {
				case Phase.POMODORO_1:
				case Phase.POMODORO_2:
				case Phase.POMODORO_3:
				case Phase.POMODORO_4:
					message = "Start Pomodoro";
					break;
				case Phase.BREAK_1:
					message = "¹Start Break";
					break;
				case Phase.BREAK_2:
					message = "²Start Break";
					break;
				case Phase.BREAK_3:
					message = "³Start Break";
					break;
				case Phase.BREAK_4:
					message = "⁴Start Long Break";
					break;
				default: error ("Should be unreachable\n");
			}
			
			var font_description = Pango.FontDescription.from_string (this.FONT_DESCRIPTION);
			double scale_by = 1024;
			
			layout.set_width((int) scale_by*200);
			layout.set_alignment (Pango.Alignment.CENTER);
			layout.set_font_description(font_description);
			layout.set_text(message,-1);
			Pango.cairo_update_layout (cr, layout);
			
			int width, height;
			layout.get_size (out width, out height);
			
			
			cr.move_to (
				100 - ((double) width)/ scale_by / 2, 
				100 - ((double) height)/ scale_by / 2);
			cr.set_operator(Cairo.Operator.OVER);
			Pango.cairo_show_layout (cr,layout);
			
		}
		return true;
	}
	private int frame_should_be () {
		if (!this.is_running) return 0;
		if (this.is_winding_up) {
			var current_time  = new TimeVal (); 
			var secs_diff     = current_time.tv_sec - this.start_time.tv_sec;
			var usecs_diff    = current_time.tv_usec - this.start_time.tv_usec;
			
			while (usecs_diff < 0) {
				secs_diff--;
				usecs_diff += 1000000;
			}
			if (secs_diff == 0 && usecs_diff < WIND_UP_DURATION) {
				return (int) (final_wind_up_frame*usecs_diff/WIND_UP_DURATION);
			}
			this.is_winding_up = false;
			this.wind_up_handler.destroy ();
			this.wind_up_handler = null;
		}
		int minutes, seconds;
		this.get_time (out minutes, out seconds);
		return (minutes*60 + seconds)/this.seconds_per_frame ;
	}
	public weak App app;
	public VisualTimer (App app, VisualTimerPreferences prefs) {
		this.preferences = prefs;
		this.app = app;
		this.anidir = Config.ANIDIR;
		this.get_pom_gtk_window().show();
		this.preferences.notify.connect((_,param) => {
				this.app.debug ("Parameter %s changed.\n", param.name);
			});
		this.preference_dialog = new VisualTimerPreferencesDialog (this) as PreferenceDialogEnabled;
	}
	public override void update_time_display (int minutes, int seconds) {
		if (this.frame_should_be () != current_frame) {
			get_pom_gtk_surface().queue_draw ();
		}
	}
	public override void toggle_show_hide () {
		if (this.is_shown) {
			int root_x, root_y;
			this._pom_gtk_window.get_position (out root_x, out root_y);
			this.preferences.position (root_x,root_y);
			this.get_pom_gtk_window().hide();
			this.is_shown = false;
		}
		else {
			if (this.preferences.is_positioned) {
				this.get_pom_gtk_window().move(this.preferences.pos_x,this.preferences.pos_y);
			}
			this.get_pom_gtk_window().show_all();
			this.is_shown = true;
		}
	}
	public override Gtk.Widget? ringing_widget () {
		return this.get_pom_gtk_surface ();
	}
	public override void destroy () {
		if (this._pom_gtk_window == null) return;
		
		int root_x, root_y;
		this._pom_gtk_window.get_position (out root_x, out root_y);
		this.preferences.position (root_x,root_y);
		
		if (this.app.ref_count == 0)      return;
		this._pom_gtk_window.destroy ();
		this.app.get_builder().add_objects_from_file (this.app.UI_FILE, {"pom-gtk-window",null});
	}
	public static TimerUI FACTORY_FUNC (App app, PreferenceEnabled? prefs) {
		var that = new VisualTimer (app, prefs as VisualTimerPreferences) ;
		return that as TimerUI;
	}
	
	construct {
		this.wind.connect_after (this.do_wind);
		this.cancel.connect_after (this.do_cancel);
		this.ring.connect_after (this.do_ring);
	}
	public void do_wind (int minutes, int seconds=0,Gtk.Widget? _ignore) {
		this.is_winding_up     = false;
		final_wind_up_frame    = this.frame_should_be ();
		
		this.start_time        = new TimeVal ();
		this.is_winding_up     = true;
		
		this.wind_up_handler   = new TimeoutSource (25);
		this.wind_up_handler.set_callback (() => {
				get_pom_gtk_surface().queue_draw();
				return true;
			});
		this.wind_up_handler.set_priority (10);
		this.wind_up_handler.attach (null);
	}
	public void do_cancel () {
		this.get_pom_gtk_surface().queue_draw();
	}
	public void do_ring () {
		this.current_phase += 1;
		if (this.current_phase > Phase.BREAK_4)
			this.current_phase = Phase.POMODORO_1;
		this.get_pom_gtk_surface().queue_draw();
	}
	
	public void run_button () {
		this.app.debug ("Reached run_button\n");
		if (this.is_running) {
			this.cancel ();
			return;
		}
		switch (this.current_phase) {
			case Phase.POMODORO_1:
			case Phase.POMODORO_2:
			case Phase.POMODORO_3:
			case Phase.POMODORO_4:
				this.wind(this.app.get_app_config().pomodoro_time,0,this.get_pom_gtk_surface());
				this.get_timer_dialog_restart().label = "Restart Pomodoro";
				break;
			case Phase.BREAK_1:
			case Phase.BREAK_2:
			case Phase.BREAK_3:
				this.wind(this.app.get_app_config().s_break_time,0,this.get_pom_gtk_surface());
				this.get_timer_dialog_restart().label = "Start Pomodoro";
				break;
			case Phase.BREAK_4:
				this.wind(this.app.get_app_config().s_break_time,0,this.get_pom_gtk_surface());
				this.get_timer_dialog_restart().label = "Start Pomodoro";
				break;
		}
	}
}
public class VisualTimerPreferences : PreferenceEnabled {
	public double opacity       {get; set;}
	public int    size          {get; set;}
	public int    pos_x         {get; private set;}
	public int    pos_y         {get; private set;}
	public bool   is_positioned {get; private set;}
	
	public void   position (int x, int y) {
		this.pos_x = x;
		this.pos_y = y;
		this.is_positioned = true;
	}
	public override void configure (KeyFile key_file) {
		try {
			this.opacity = key_file.get_double ("VisualTimerPreferences","opacity");
		}
		catch (KeyFileError err) {
			this.opacity  = 1;
			this.has_changed();
		}
		try {
			this.size = key_file.get_integer ("VisualTimerPreferences","size");
		}
		catch (KeyFileError err) {
			this.size  = 180;
			this.has_changed();
		}
		
		try {
			this.pos_x = key_file.get_integer ("VisualTimerPreferences","pos-x");
			this.pos_y = key_file.get_integer ("VisualTimerPreferences","pos-y");
			this.is_positioned = true;
		}
		catch (KeyFileError err) {
			this.is_positioned = false;
			this.has_changed();
		}
	}
	public override void configure_from_default () {
		this.opacity = 1;
		this.size    = 180;
		this.is_positioned = false;
		this.has_changed();
	}
	public override void commit (KeyFile key_file) {
		key_file.set_double ("VisualTimerPreferences","opacity",this.opacity);
		key_file.set_integer ("VisualTimerPreferences","size",this.size);
		if (this.is_positioned) {
			key_file.set_integer ("VisualTimerPreferences","pos-x",this.pos_x);
			key_file.set_integer ("VisualTimerPreferences","pos-y",this.pos_y);
		}
	}
	public static PreferenceEnabled FACTORY_FUNC () {
		var that = new VisualTimerPreferences ();
		return that as PreferenceEnabled;
	}
	construct {
		this.notify.connect((_1,_2) => {
				this.has_changed ();
			});
	}
}
public class VisualTimerPreferencesDialog : PreferenceDialogEnabled {
	private Gtk.Grid _subdialog;
	private Gtk.Adjustment _opacity_adjustment;
	private Gtk.Adjustment _size_adjustment;
	
	private VisualTimerPreferences preferences;
	
	private weak VisualTimer ui;
	
	private int previous_size;
	private double previous_opacity;
	
	private Gtk.Grid get_subdialog () {	
		if (this._subdialog == null) 
		{	this._subdialog = 
				this.ui.app.get_builder().get_object("visual-timer-preferences-subdialog") as Gtk.Grid ;
			this.get_opacity_adjustment().notify["value"].connect(() => {
					this.preferences.opacity = this.get_opacity_adjustment().value ;
				});
			this.get_size_adjustment().notify["value"].connect(() => {
					this.preferences.size = (int) this.get_size_adjustment().value ;
				});
		}
		return this._subdialog;
	}
	private Gtk.Adjustment get_opacity_adjustment () {
		if (this._opacity_adjustment == null) {
			this._opacity_adjustment = 
				this.ui.app.get_builder().get_object("visual-timer-preferences-opacity-adjustment") as Gtk.Adjustment ;
		}
		return this._opacity_adjustment;
	}
	private Gtk.Adjustment get_size_adjustment () {
		if (this._size_adjustment == null) {
			this._size_adjustment = 
				this.ui.app.get_builder().get_object("visual-timer-preferences-size-adjustment") as Gtk.Adjustment ;
		}
		return this._size_adjustment;
	}

	public VisualTimerPreferencesDialog (VisualTimer ui) {
		this.ui = ui;
		this.preferences = this.ui.preferences;
	}
	public override void instantiate (Gtk.Bin container) {
		container.child = get_subdialog() ;
	}
	public override void show () {
		this.get_opacity_adjustment().value = this.previous_opacity = this.preferences.opacity ;
		this.get_size_adjustment().value    = this.previous_size = this.preferences.size;
		
		get_subdialog().show ();
	}
	public override void hide () {
		if (this._subdialog != null) {
			this._subdialog.destroy();
		}
		this._subdialog          = null;
		this._opacity_adjustment = null;
		this._size_adjustment    = null;
		this.ui.app.get_builder().add_objects_from_file (this.ui.app.UI_FILE, 
			{"visual-timer-preferences-subdialog",
			 "visual-timer-preferences-opacity-adjustment",
			 "visual-timer-preferences-size-adjustment",null});
	}
	public override void try_commit () {;}
	public override void try_uncommit () {
		this.preferences.opacity = this.previous_opacity;
		this.preferences.size    = this.previous_size;
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
	public PreferenceDialogEnabled? preference_dialog {get; protected set;}
	public abstract SoundEvent? play (SoundBite sound, Gtk.Widget? widget);
	public abstract SoundLoop?  loop (SoundBite sound, Gtk.Widget? widget);
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
	public override SoundLoop? loop (SoundBite _1, Gtk.Widget? _2 ) {
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
public class GStreamerSoundHandler : SoundHandler {
	private unowned App app;
	private string? ringing_sound;
	private string? wind_sound;
	private string? ticking_sound;
	private int  index = 0;
	
	public GStreamerSoundHandler (App app) {
		this.app = app;
		// This needs to be moved to preferences.
		this.ringing_sound = Filename.to_uri(Path.build_filename(Config.SOUNDSDIR,"ring.ogg",null));
		this.wind_sound    = Filename.to_uri(Path.build_filename(Config.SOUNDSDIR,"wind.ogg",null));
		this.ticking_sound = Filename.to_uri(Path.build_filename(Config.SOUNDSDIR,"tick-loop.ogg",null));
	}
	public static SoundHandler FACTORY_FUNC (App app)  {
		var that = new GStreamerSoundHandler (app);
		return that as SoundHandler;
	}
	private string? parse_soundbite (SoundBite id) {
		switch (id) {
			case SoundBite.RING:
				return this.ringing_sound;
			case SoundBite.WIND:
				return this.wind_sound;
			case SoundBite.TICK_TOCK:
				return this.ticking_sound;
			default:
				return null;
		}
	}
	public override void destroy () {return;}
	private Gst.Pipeline? play_or_loop (SoundBite sound,out string uri = null) {
		var file_uri = this.parse_soundbite(sound);
		uri = file_uri;
		
		if (file_uri == null) return null;
		
		dynamic Gst.Pipeline playbin  = Gst.ElementFactory.make("playbin",("pipeline-%d").printf(this.index)) as Gst.Pipeline;
		dynamic Gst.Element fakesink = Gst.ElementFactory.make("fakesink",("fakesink-%d").printf(this.index++));
		playbin.video_sink = fakesink;
		playbin.uri        = file_uri;
		return playbin;
	}
	public override SoundEvent? play (SoundBite sound, Gtk.Widget? _) {
		Gst.Pipeline? playbin  = this.play_or_loop (sound);
		if (playbin == null) return null;
		
		playbin.set_state(Gst.State.PLAYING);
		return new GStreamerEvent (playbin) as SoundEvent;
	}
	public override SoundLoop? loop (SoundBite sound, Gtk.Widget? _) {
		string uri;
		Gst.Pipeline? playbin  = this.play_or_loop (sound);
		if (playbin == null) return null;
		
		var loop_control = new GStreamerLoop (playbin) as SoundLoop;
		
		playbin.set_state(Gst.State.PLAYING);
		return loop_control;
	}
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
public class GStreamerEvent : SoundEvent {
	private weak Gst.Element playbin;
	
	public GStreamerEvent (Gst.Element playbin) {
		this.playbin = playbin;
	}
	public override void cancel () {
		this.playbin.set_state(Gst.State.NULL);
	} 
}
public abstract class SoundLoop : SoundEvent {
}
public class GStreamerLoop : SoundLoop {
	private bool is_looping;
	private SoundBite sound;
	private string uri;
	private Gst.Pipeline playbin;
	
	
	bool bus_watcher (Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
			case Gst.MessageType.EOS:
				if (this.is_looping) 
					playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, 0);
				return this.is_looping;
			default: break;
		}
		return true;
	}
	public GStreamerLoop (Gst.Pipeline playbin) {
		this.is_looping = true;
		this.uri = uri;
		this.playbin = playbin;
		var bus = playbin.get_bus ();
		bus.add_watch (this.bus_watcher);
	}
	public override void cancel () {
		this.is_looping = false;
		this.playbin.set_state(Gst.State.NULL);
	}
}
}
