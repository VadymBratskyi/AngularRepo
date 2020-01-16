Terrasoft.ReportPreview = Ext.extend(Terrasoft.SilverlightContainer, {
	reportZoom: 100,
	reportSchemaUId: '',
	width: 300,
	height: 300,
	source: "/ClientBin/Terrasoft.UI.WindowsControls.Report.xap",

	initComponent: function () {
		this.parameters = {};
		this.parameters.source = this.source;
		Terrasoft.ReportPreview.superclass.initComponent.call(this);
		this.addEvents('ready', 'pluginready');
		if (!this.designMode) {
			this.on("pluginready", function() {
				if (this.rendered) {
					this.fireEvent('ready', this, {});
				}
			});
			this.on("rendercomplete", function() {
				if (this.scriptableObject) {
					this.fireEvent('ready', this, {});
				}
			});
		}
		this.on("onpluginloaded", function() {
			if (!this.scriptableObject) {
				return;
			}
			this.scriptableObject.ApplicationPath = Terrasoft.applicationPath;
			this.pluginReady = true;
			if (!this.designMode) {
				this.fireEvent('pluginready', this, {});
			}
			if (this.reportSchemaUId && this.reportSchemaUId != '') {
				this.scriptableObject.LoadReport(this.reportSchemaUId);
			}
		}, this);
	},

	setReportSchemaUId: function(reportSchemaUId) {
		this.reportSchemaUId = reportSchemaUId;
		if (!this.pluginReady) {
			return;
		}
		this.scriptableObject.LoadReport(reportSchemaUId);
	},

	getResizeEl: function() {
		return this.el;
	},

	setEdges: function(edgesValue) {
		if (edgesValue) {
			var resizeEl = this.getResizeEl();
			resizeEl.addClass("x-container-border");
			var edges = edgesValue.split(" ");
			var style = resizeEl.dom.style;
			style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
			style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
			style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
			style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
		}
	},

	onRender: function (ct, position) {
		Terrasoft.ReportPreview.superclass.onRender.call(this, ct, position);
		var el = this.el;
		el.addClass('x-report-preview');
		if (!this.edges) {
			return;
		}
		var edges = this.edges.split(" ");
		var style = el.dom.style;
		style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
		style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
		style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
		style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
	},

	onCustomEvent: function (sender, args) {
	}
});

Ext.reg("reportpreview", Terrasoft.ReportPreview);