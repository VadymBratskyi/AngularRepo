Terrasoft.ChartSeries = Ext.extend(Ext.Component, {
	seriesKind: 'line',

	initComponent: function() {
		Terrasoft.ChartSeries.superclass.initComponent.call(this);
		this.points = [];
		this.addEvents('kindchange', 'captionchange', 'clearpoints');
		window[this.id] = this;
	},

	clearPoints: function(fireEvent) {
		this.points = [];
		if (fireEvent) {
			this.fireEvent('clearpoints', this.id, {});
		}
	},

	addPoint: function(point) {
		this.points.push(point);
	},

	addPoints: function(points) {
		Ext.each(points, function(pt) {
			this.addPoint(pt);
		}, this);
	},

	setSeriesKind: function(seriesKind) {
		this.seriesKind = seriesKind;
		this.fireEvent('kindchange', this.id, seriesKind);
	},

	setCaption: function(caption) {
		if (this.caption == caption) {
			return;
		}
		this.caption = caption;
		this.fireEvent('captionchange', this.id, caption);
	}
});

Ext.reg("chartseries", Terrasoft.ChartSeries);

Terrasoft.ChartAxis = Ext.extend(Ext.Component, {
	location: 'bottom',

	initComponent: function() {
		Terrasoft.ChartAxis.superclass.initComponent.call(this);
		window[this.id] = this;
		this.addEvents('locationchange', 'captionchange');
	},

	setLocation: function(location) {
		if (this.location == location) {
			return;
		}
		this.location = location;
		var axisIndex = this.getXType() == 'chartxaxis' ? 0 : 1;
		this.fireEvent('locationchange', axisIndex, location);
	},

	setCaption: function(caption) {
		if (this.caption == caption) {
			return;
		}
		this.caption = caption;
		var axisIndex = this.getXType() == 'chartxaxis' ? 0 : 1;
		this.fireEvent('captionchange', axisIndex, caption);
	}
});

Terrasoft.ChartXAxis = Ext.extend(Terrasoft.ChartAxis, {
	location: 'bottom'
});

Ext.reg("chartxaxis", Terrasoft.ChartXAxis);

Terrasoft.ChartYAxis = Ext.extend(Terrasoft.ChartAxis, {
	location: 'left'
});

Ext.reg("chartyaxis", Terrasoft.ChartYAxis);

Terrasoft.Chart = function(cfg) {
	cfg = cfg || {};
	Ext.apply(this, cfg);
	this.series = [];
	this.axis = [];
	if (this.seriesConfig) {
		if (!Ext.isArray(this.seriesConfig)) {
			this.seriesConfig = [this.seriesConfig];
		}
		this.fillSeries(this.seriesConfig);
		delete this.seriesConfig;
	}
	if (this.axisConfig) {
		this.fillAxis(this.axisConfig);
		delete this.axisConfig;
	}
	this.caption = cfg.caption;
	Terrasoft.Chart.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.Chart, Ext.LayoutControl, {
	width: 300,
	height: 300,
	legendPosition: 'bottom',
	dataLabelFormat: '',
	toolTipFormat: '',
	percentCode: '[#Percent#]',
	pointNameCode: '[#PointName#]',
	coordinateXCode: '[#XValue#]',
	coordinateYCode: '[#YValue#]',
	defaultToolTipNotPieChart: '<b>[#XValue#]</b>: [#YValue#]',
	defaultToolTipPieChart: '<b>[#PointName#]</b>: [#Percent#] %',
	defaultDataLabelPieChart: '[#PointName#] ([#YValue#])',

	initComponent: function() {
		Terrasoft.Chart.superclass.initComponent.call(this);
		var chartStringList = Ext.StringList('WC.Chart');
		this.parameters = {};
		this.parameters.source = this.source;
		Highcharts.setOptions({
			colors: ['#058DC7', '#50B432', '#ED561B', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4'],
			lang: {
				resetZoom: chartStringList.getValue('ResetZoom.Caption'),
				resetZoomTitle: ''
			}
		});
	},

	onRender: function(container, position) {
		Terrasoft.Chart.superclass.onRender.call(this, container, position);
		if (!this.el) {
			var el = this.el = container.createChild({
				tag: 'div',
				cls: 'x-chart',
				id: this.id || this.getId()
			});
			if (!Ext.isEmpty(this.cls)) {
				el.addClass(this.cls);
			}
			if (this.designMode) {
				this.drawChartInDesignMode();
			}
			this.setEdges(this.edges);
		}
		this.drawChart();
	},

	setCaption: function(caption) {
		if (this.caption == caption) {
			return;
		}
		this.setTitle(caption);
	},

	setTitle: function(title, subtitle) {
		this.caption = title;
		this.subtitle = subtitle;
		if (!this.chart) {
			return;
		}
		this.chart.setTitle({ text: title }, { text: subtitle });
	},

	onResize: function() {
		Terrasoft.Chart.superclass.onResize.call(this);
		if (this.chart) {
			this.adjustChartSize();
		}
	},

	adjustChartSize: function() {
		var el = this.el;
		var width = this.getWidth() - el.getBorderWidth("lr");
		var height = this.getHeight() - el.getBorderWidth("tb");
		this.chart.setSize(width, height, false);
	},

	fillSeries: function(config) {
		if (!config) {
			return;
		}
		Ext.each(config, function(seriesItemConfig) {
			var series = new Terrasoft.ChartSeries({
				id: seriesItemConfig.id,
				caption: seriesItemConfig.caption,
				seriesKind: seriesItemConfig.seriesKind
			});
			this.addSeries(series);
		}, this);
	},

	fillAxis: function(config) {
		if (!config) {
			return;
		}
		Ext.each(config, function(axisItemConfig) {
			var transformedConfig = {
				id: axisItemConfig.id,
				caption: axisItemConfig.caption,
				visibility: axisItemConfig.hidden,
				location: axisItemConfig.location,
				hidden: axisItemConfig.hidden
			};
			var axis = Ext.ComponentMgr.create(transformedConfig, axisItemConfig.xtype);
			this.addAxis(axis);
		}, this);
	},

	addSeries: function(item) {
		item.on('kindchange', this.onSeriesKindChange, this);
		item.on('captionchange', this.onSeriesCaptionChange, this);
		item.on('clearpoints', this.onSeriesClearPoints, this);
		this.series.push(item);
	},

	addAxis: function(item) {
		item.on('captionchange', this.onAxisCaptionChange, this);
		item.on('locationchange', this.onAxisLocationChange, this);
		this.axis.push(item);
	},

	setEdges: function(edgesValue) {
		if (!edgesValue) {
			return;
		}
		var resizeEl = this.getResizeEl();
		if (!resizeEl) {
			return;
		}
		resizeEl.addClass("x-container-border");
		var edges = edgesValue.split(" ");
		var style = resizeEl.dom.style;
		style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
		style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
		style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
		style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
	},

	drawChartInDesignMode: function() {
		var series = this.series;
		Ext.each(series, function(seriesItem) {
			seriesItem.addPoints([
				{ x: 0, y: 10 },
				{ x: 10, y: 20 },
				{ x: 20, y: 30 }
			]);
		});
		this.drawChart();
	},

	getUpdatedPieChartCode: function (stringWithCode, percent, yValue, pointName) {
		stringWithCode = stringWithCode.replace(this.percentCode, percent);
		stringWithCode = stringWithCode.replace(this.coordinateYCode, yValue);
		stringWithCode = stringWithCode.replace(this.pointNameCode, pointName);
		return stringWithCode;
	},

	getUpdatedNotPieChartCode: function (stringWithCode, xValue, yValue) {
		stringWithCode = stringWithCode.replace(this.coordinateXCode, xValue);
		stringWithCode = stringWithCode.replace(this.coordinateYCode, yValue);
		return stringWithCode;
	},

	getToolTipString: function (chart, defaultToolTip, isPieChart) {
		var toolTipString = this.toolTipFormat || defaultToolTip;
		if (isPieChart) {
			return this.getUpdatedPieChartCode(toolTipString, Highcharts.numberFormat(chart.percentage, 1), chart.y,
				chart.point.name);
		}
		return this.getUpdatedNotPieChartCode(toolTipString, chart.x, chart.y);
	},

	getDataLabelString: function (chart, defaultDataLabel) {
		var dataLabelString = this.dataLabelFormat || defaultDataLabel;
		return this.getUpdatedPieChartCode(dataLabelString, Highcharts.numberFormat(chart.percentage, 1), chart.y,
			chart.point.name);
	},

	drawChart: function() {
		if(!this.el) {
			return;
		}
		this.pointType = this.getSeriesPointType();
		this.convertedXAxis = this.convertAxis(this.axis[0]);
		this.convertedYAxis = this.convertAxis(this.axis[1]);
		var legend = this.convertLegend(this.legendPosition);
		var xAxis = this.convertedXAxis;
		var yAxis = this.convertedYAxis;
		xAxis.labels = {
			staggerLines: 2
		};
		var chartSeries = [];
		var isPieChart = false;
		if (this.series && this.series.length > 0) {
			isPieChart = (this.convertSeriesKind(this.series[0].seriesKind) == "pie");
		}
		if (this.pointType == "strnum" && !isPieChart) {
			chartSeries = this.convertAllSeries();
		} else {
			Ext.each(this.series, function(seriesItem) {
				chartSeries.push(this.convertSeries(seriesItem));
			}, this);
		}
		var chartConfig = this.getChartConfig(xAxis, yAxis, legend, chartSeries, isPieChart);
		this.chart = new Highcharts.Chart(chartConfig);
		this.adjustChartSize();
	},

	getChartConfig: function(xAxis, yAxis, legend, chartSeries, isPieChart) {
		var hightchart = this;
		var config = {
			chart: {
				renderTo: this.el.id,
				reflow: false,
				zoomType: "xy",
				resetZoomButton: {
					theme: {
						fill: 'white',
						stroke: 'silver',
						r: 0,
						states: {
							hover: {
								fill: '#41739D',
								style: {
									color: 'white'
								}
							}
						}
					}
				}
			},
			credits: {
				enabled: false
			},
			legend: legend,
			xAxis: xAxis,
			yAxis: yAxis,
			series: chartSeries,
			title: {
				text: this.caption || ""
			},
			tooltip: {
				formatter: function () {
					var defaultToolTip = isPieChart ? hightchart.defaultToolTipPieChart :
						hightchart.defaultToolTipNotPieChart;
					return hightchart.getToolTipString(this, defaultToolTip, isPieChart);
				}
			},
			plotOptions: {
				scatter: {
					marker: {
						radius: 5,
						states: {
							hover: {
								enabled: true,
								lineColor: 'rgb(100,100,100)'
							}
						}
					}
				},
				pie: {
					allowPointSelect: true,
					cursor: 'pointer',
					dataLabels: {
						enabled: true,
						formatter: function () {
							return hightchart.getDataLabelString(this, hightchart.defaultDataLabelPieChart);
						}
					}
				}
			},
			lang: {
				exportButtonTitle: ""
			},
			exporting: {
				url: Terrasoft.applicationPath + "/HighchartsExportHandler.ashx",
				buttons: {
					exportButton: {
						menuItems: null,
						onclick: function() {
							this.exportChart();
						},
						enabled: false
					},
					printButton: {
						enabled: false
					}
				}
			}
		};
		return config;
	},

	convertAxis: function(axis) {
		var axisType = "linear";
		if ((this.pointType == "dtnum" && axis.xtype == "chartxaxis") || 
				(this.pointType == "numdt" && axis.xtype == "chartyaxis")) {
			axisType = "datetime";
		}
		var axisLocation;
		if (axis.location) {
			axisLocation = axis.location.toLowerCase();
		}
		var convertedAxis = {
			id: axis.name,
			type: axisType,
			title: {
				text: axis.caption || ""
			},
			opposite: (axisLocation == "top" || axisLocation == "right")
		};
		return convertedAxis;
	},

	convertAllSeries: function() {
		var categories = [];
		var chartSeries = [];
		var pointsData = new Ext.util.MixedCollection();
		Ext.each(this.series, function(seriesItem, seriesIndex) {
			var affectedCategories = {};
			Ext.each(seriesItem.points, function(point) {
				var category = point.x;
				var value = point.y;
				if (!pointsData[category]) {
					pointsData.add(category, []);
					categories.push(category);
					for (var i = 0; i < seriesIndex; i++) {
						var pointData = pointsData.get(category);
						pointData.push(null);
					}
				}
				var pointData = pointsData.get(category);
				pointData.push(value);
				affectedCategories[category] = {};
			}, this);
			pointsData.eachKey(function(category) {
				if (!affectedCategories[category]) {
					var pointData = pointsData.get(category);
					pointData.push(null);
				}
			});
			chartSeries.push({
				type: this.convertSeriesKind(seriesItem.seriesKind),
				name: seriesItem.caption || "",
				data: []
			});
		}, this);
		this.convertedXAxis.categories = categories;
		Ext.each(chartSeries, function(seriesItem, seriesIndex) {
			pointsData.each(function(pointData) {
				seriesItem.data.push(pointData[seriesIndex]);
			});
		}, this);
		return chartSeries;
	},

	convertSeries: function(seriesItem) {
		var convertedPoints = [];
		Ext.each(seriesItem.points, function(point) {
			var convertedPoint = this.convertSeriesPoint(point);
			convertedPoints.push(convertedPoint);
		}, this);
		var convertedSeries = {
			type: this.convertSeriesKind(seriesItem.seriesKind),
			name: seriesItem.caption || "",
			data: convertedPoints
		};
		return convertedSeries;
	},

	convertSeriesPoint: function(point) {
		var convertedPoint = point;
		if (this.pointType == "dtnum") {
			convertedPoint = [Date.UTC(point.x.getFullYear(), point.x.getMonth(), point.x.getDate()), point.y];
		} else if (this.pointType == "numdt") {
			convertedPoint = [point.x, Date.UTC(point.y.getFullYear(), point.y.getMonth(), point.y.getDate())];
		} else if (this.pointType == "strnum") {
			convertedPoint = [point.x, point.y];
		}
		return convertedPoint;
	},

	convertSeriesKind: function(seriesKind) {
		return (seriesKind) ? seriesKind.toLowerCase() : null;
	},

	convertLegend: function(legendPosition) {
		var pos = legendPosition.toLowerCase();
		var legendConfig;
		if (pos == "right" || pos == "left") {
			legendConfig = {
				align: pos,
				verticalAlign: 'middle',
				layout: 'vertical'
			};
		} else if (pos == "top" || pos == "bottom") {
			legendConfig = {
				align: "center",
				verticalAlign: pos
			};
		} else {
			legendConfig = {
				enabled: false
			};
		}
		return legendConfig;
	},

	getSeriesPointType: function() {
		var result = "num";
		Ext.each(this.series, function(seriesItem) {
			if (seriesItem.points.length > 0) {
				var point = seriesItem.points[0];
				var xType = typeof point.x;
				var yType = typeof point.y;
				if (xType == 'number' && yType == 'number') {
					result = "num";
				} else if (xType == 'string' && yType == 'number') {
					result = "strnum";
				} else if (xType == 'object' && yType == 'number') {
					result = "dtnum";
				} else if (xType == 'number' && yType == 'object') {
					result = "numdt";
				}
				return false;
			}
		}, this);
		return result;
	},

	onAxisCaptionChange: function(index, caption) {
		this.drawChart();
	},

	onAxisLocationChange: function(index, location) {
		this.drawChart();
	},

	onSeriesKindChange: function(name, kind) {
		this.drawChart();
	},

	onSeriesCaptionChange: function(name, caption) {
		this.drawChart();
	},

	onSeriesClearPoints: function(name) {
		this.drawChart();
	}
});

Ext.reg("chart", Terrasoft.Chart);