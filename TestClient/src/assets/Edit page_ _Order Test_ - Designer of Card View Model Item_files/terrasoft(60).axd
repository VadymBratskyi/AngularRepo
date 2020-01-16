Terrasoft.DiagramContainer = Ext.extend(Terrasoft.HtmlPageContainer, {

	initComponent: function() {
		Terrasoft.DiagramContainer.superclass.initComponent.call(this);
		Ext.EventManager.addListener(window, "message", this.onMessageReceived, this);
		this.addEvents(
			"messagereceived"
		);
		if (!window.location.origin) {
			window.location.origin = window.location.protocol + "//" +
				window.location.hostname + (window.location.port ? ":" + window.location.port : "");
		}
	},

	onRender: function(ct, position) {
		this.sourceUrl = this.getSourceUrl(window.location);
		Terrasoft.DiagramContainer.superclass.onRender.call(this, ct, position);
	},

    parseProcessId: function(path) {
        var schemaUIdRegexp = /Id=([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}).*/i;
        var result = schemaUIdRegexp.exec(path);
        return result && result[1];
    },

	getSourceUrl: function(location) {
	    var processId = this.parseProcessId(location.search);
	    var url = processId
		    ? "../Nui/ViewModule.aspx?vm=SchemaDesigner#process5x/" + processId
	        : "./Nui/ViewModule.aspx?vm=SchemaDesigner#packageDependenciesDiagram";
		return url;
	},

	onMessageReceived: function(event) {
		var browserEvent = event.browserEvent;
		if (browserEvent.origin !== window.location.origin) {
			return;
		}
		var request = Ext.decode(browserEvent.data);
		this.fireEvent("messagereceived", {
			request: request,
			source: browserEvent.source
		});
	},

	onFrameLoad: function() {
		var body = this.getEditorBody();
		var element = Ext.get(body);
		element.on("mousedown", this.onMouseDown);
	},

	onMouseDown: function() {
		var focusedControl = Terrasoft.FocusManager.getFocusedControl();
		if (focusedControl) {
			focusedControl.unFocus();
		}
	}
});

Ext.reg("diagramcontainer", Terrasoft.DiagramContainer);
