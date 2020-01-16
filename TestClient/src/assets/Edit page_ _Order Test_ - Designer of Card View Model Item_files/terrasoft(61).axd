Terrasoft.AceEditWrap = Ext.extend(Ext.form.TextField, {
	width: 300,
	height: 200,
	ownerCt: null,
	aceInitialized: false,
	aceLoaded: false,
	aceEdit: null,
	aceResourceManagerName: 'Terrasoft.UI.WebControls',
	aceResourceItemName: 'ace-terrasoft-build-5x.js',
	loadScriptTemplate: "{0}/terrasoft.axd?rm={1}&r={2}",
	allowEmpty: true,
	isWhitespaceVisible: true,
	language: "csharp",
	theme: "crimson_editor",
	editorMode: "ace/mode/csharp",
	value: "",
	readOnly: false,

	initComponent: function() {
		Terrasoft.AceEditWrap.superclass.initComponent.call(this);
		this.loadAce();
		Object.defineProperty(this, "IsReadOnly", {
			get: this.isReadOnlyGetter,
			set: this.isReadOnlySetter,
			enumerable: true
		});
		this.addEvents(
			"aceinitialized",
			"FocusChanged"
		);
	},

	isReadOnlyGetter: function() {
		return this.aceEdit.getReadOnly();
	},

	isReadOnlySetter: function(value) {
		this.aceEdit.setReadOnly(value);
	},

	loadAce: function() {
		if (!window.ace || this.aceLoaded === true) {
			this.aceLoaded = true;
			var aceScriptUrl = String.format("{0}/terrasoft.axd?rm={1}&r={2}",
				Terrasoft.applicationPath, this.aceResourceManagerName, this.aceResourceItemName);
			Terrasoft.ScriptLoader.loadScript(aceScriptUrl, this.initAceEdit, null, this);
		} else {
			this.initAceEdit();
		}
	},

	initAceEdit: function() {
		if (this.rendered !== true) {
			return;
		}
		window.edit = this;
		var aceEdit = this.aceEdit = ace.edit(this.id + "_edit-el");
		ace.require('ace/ext/settings_menu').init(aceEdit);
		//aceEdit.commands.addCommands([{
		//	name: "showSettingsMenu",
		//	bindKey: {
		//		win: "Ctrl-q",
		//		mac: "Command-q"
		//	},
		//	exec: function (editor) {
		//		editor.showSettingsMenu();
		//	}
		//}]);
		aceEdit.setTheme("ace/theme/crimson_editor");
		var aceEditSession = aceEdit.getSession();
		aceEditSession.setMode(this.editorMode);
		aceEdit.setOptions({
			enableBasicAutocompletion: true,
			enableSnippets: true,
			enableLiveAutocompletion: true,
			printMargin: 120,
			useSoftTabs: false,
			showInvisibles: this.isWhitespaceVisible,
			readOnly: this.readOnly
		});
		aceEditSession.setValue(this.value);
		aceEdit.focus();
		aceEdit.on("blur", this.onAceBlur.bind(this));
		this.aceInitialized = true;
		this.fireEvent("aceinitialized");
	},

	onAceBlur: function() {
		this.fireEvent("FocusChanged", this, {
			EventName: "FocusChanged"
		});
	},

	onRender: function(ct, position) {
		Terrasoft.AceEditWrap.superclass.onRender.call(this, ct, position);
		this.editEl = this.el.insertSibling({
			tag: "div",
			name: this.id + "_edit-el",
			id: this.id + "_edit-el",
			cls: "aceEditor",
			style: {
				position: "absolute",
				top: 0,
				left: 0,
				bottom: 0,
				right: 0,
				border: "1px solid #85888E"
			}
		});
		this.ownerCt.on("resize", this.onSizeChanged, this);
		this.loadAce();
	},

	onSizeChanged: function() {
		if (this.aceInitialized) {
			this.aceEdit.resize(true);
		}
	},

	GetText: function() {
		if (this.aceInitialized) {
			var aceEditSession = this.aceEdit.getSession();
			return aceEditSession.getValue();
		}
		return this.value;
	},

	SetText: function(text) {
		this.value = Ext.util.Format.htmlDecode(text) || "";
		if (this.aceInitialized) {
			var aceEditSession = this.aceEdit.getSession();
			this.aceEdit.focus();
			aceEditSession.setValue(this.value);
		}
	},

	SetCaretPosition: function(line, column) {
		if (this.aceInitialized) {
			this.aceEdit.gotoLine(line, column);
			this.aceEdit.focus();
		}
	},

	SwitchSearchViewVisible: function() {
		if (this.aceInitialized) {
			this.aceEdit.execCommand("find");
			this.aceEdit.searchBox.searchInput.focus();
		}
	},

	SwitchWhitespaceVisible: function() {
		this.isWhitespaceVisible = !this.isWhitespaceVisible;
		if (this.aceInitialized) {
			this.aceEdit.setShowInvisibles(this.isWhitespaceVisible);
		}
	},

	OnWindowMouseUp: function() {
	},

	SetHeaderAndFooterText: function() {
	},

	SetLanguage: function(language) {
		this.language = language;
		switch (language) {
			case "javascript":
				this.editorMode = "ace/mode/javascript";
				break;
			case "csharp":
				this.editorMode = "ace/mode/csharp";
				break;
			case "less":
				this.editorMode = "ace/mode/less";
				break;
			case "css":
				this.editorMode = "ace/mode/css";
				break;
			case "sql":
				this.editorMode = "ace/mode/sql";
				break;
			case "sqlserver":
				this.editorMode = "ace/mode/sqlserver";
				break;
		}
		if (this.aceInitialized) {
			var aceEditSession = this.aceEdit.getSession();
			aceEditSession.setMode(this.editorMode);
		}
	},

	setTheme: function(theme) {
		this.theme = theme;
		var themePath;
		switch (theme) {
			case "sqlserver":
				themePath = "ace/theme/sqlserver";
				break;
			default:
				themePath = "ace/theme/crimson_editor";
		}
		if (this.aceInitialized) {
			this.aceEdit.setTheme(themePath);
		}
	},

	onDestroy: function() {
		if (this.aceInitialized) {
			var aceEdit = this.aceEdit;
			aceEdit.off("blur", this.onAceBlur);
			aceEdit.destroy();
		}
		Terrasoft.AceEditWrap.superclass.onDestroy.call(this);
	}

});