Ext.namespace("Terrasoft.treegrid");

Terrasoft.SaveMask = function(el, config) {
	this.el = Ext.get(el);
	Ext.apply(this, config);
	if (this.writeStore) {
		this.writeStore.on("beforesave", this.onBeforeSave, this);
		this.writeStore.on("save", this.onSave, this);
		this.writeStore.on("saveexception", this.onSave, this);
		this.writeStore.on("commitdone", this.onSave, this);
		this.writeStore.on("commitfailed", this.onSave, this);
		this.removeMask = Ext.value(this.removeMask, false);
	}
};

Terrasoft.SaveMask.prototype = {
	msg: "Saving...",
	msgCls: "x-mask-loading",
	disabled: false,

	disable: function() {
		this.disabled = true;
	},

	enable: function() {
		this.disabled = false;
	},

	onSave: function() {
		this.el.unmask(this.removeMask);
	},

	onBeforeSave: function() {
		if (!this.disabled) {
			this.el.mask(this.msg, this.msgCls);
		}
	},

	show: function() {
		this.onBeforeSave();
	},

	hide: function() {
		this.onSave();
	},

	destroy: function() {
		if (this.writeStore) {
			this.writeStore.un("beforesave", this.onBeforeSave, this);
			this.writeStore.un("save", this.onSave, this);
			this.writeStore.un("saveexception", this.onSave, this);
			this.writeStore.un("commitdone", this.onSave, this);
			this.writeStore.un("commitfailed", this.onSave, this);
		}
	}
};

Terrasoft.treegrid.AbstractSelectionModel = function(config) {
	this.activeNode = null;
	this.selMap = {};
	this.selData = [];
	this.selNodes = [];
	this.addEvents(
		"beforeselect"
	);
	Ext.apply(this, config);
	Terrasoft.treegrid.AbstractSelectionModel.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.treegrid.AbstractSelectionModel, Ext.util.Observable, {

	init: function() {
		var focusEl = this.treegrid.view.focusEl;
		this.initKeyDown(focusEl);
		focusEl.on("focus", this.onFocus, this);
		focusEl.on("blur", this.onBlur, this);
	},

	selectPrevious: function(e) {
		var s = this.activeNode;
		if (!s) {
			return null;
		}
		var ps = s.previousSibling;
		if (ps) {
			if (!ps.isExpanded() || ps.childNodes.length < 1) {
				return this.select(ps, false);
			} else {
				var lc = ps.lastChild;
				if (lc && lc.isPaging){
					lc = lc.previousSibling;
				}
				while (lc && lc.isExpanded() && lc.childNodes.length > 0) {
					lc = lc.lastChild;
					if (lc && lc.isPaging){
						lc = lc.previousSibling;
					}
				}
				return this.select(lc, false);
			}
		} else if (s.parentNode && !s.parentNode.isRoot) {
			return this.select(s.parentNode, false);
		}
		return null;
	},

	selectNext: function(e) {
		var s = this.activeNode;
		if (!s) {
			return null;
		}
		if (s.firstChild && s.isExpanded()) {
			return this.select(s.firstChild, false);
		} else if (s.nextSibling && !s.nextSibling.isPaging) {
			return this.select(s.nextSibling, false);
		} else if (s.parentNode) {
			var newS = null;
			s.parentNode.bubble(function() {
				if (this.nextSibling && !this.nextSibling.isPaging) {
					var selModel = this.getTreeGrid().selModel;
					newS = selModel.select(this.nextSibling, false);
					return false;
				}
			});
			return newS;
		}
		return null;
	},

	selectNextSibling: function() {
		var s = this.activeNode;
		if (!s) {
			return null;
		}
		if (s.nextSibling && !s.nextSibling.isPaging) {
			return this.select(s.nextSibling, false);
		}
		return null;
	},

	onNodeClick: function(node, e) {
		
	},

	onContextMenu: function(e) {
		var treegrid = this.treegrid;
		if (treegrid.handleContextMenu) {
			return;
		}
		var node = treegrid.eventModel.getNode(e);
		if (node) {
			this.onNodeClick(node, e);
			var row = treegrid.dataSource.getRow(node.id);
			treegrid.fireEvent("nodecontextmenu", treegrid, Ext.encode(row.columns));
		}
	},
	
	onHandleContextMenu: function(e) {
		var treeGrid = this.treegrid;
		var eventModel = treeGrid ? treeGrid.eventModel : null;
		if (eventModel) {
			var node = eventModel.getNode(e);
			if (node) {
				if (!node.isSelected()) {
					this.onNodeClick(node, e);
				}
				var row = treeGrid.dataSource.getRow(node.id);
				treeGrid.fireEvent("nodecontextmenu", treeGrid, Ext.encode(row.columns));
			}
		}
	},
	
	setActiveNode: function(node, cellIndex) {
		this.blurActiveCell();
		if (node != this.activeNode) {
			this.activeNode = node;
			this.treegrid.dataSource.setActiveRow(node ? node.id : node);
		}
		if (Ext.isEmpty(cellIndex)) {
			cellIndex = this.activeCellIndex;
		}
		if (Ext.isEmpty(cellIndex)) {
			cellIndex = this.treegrid.columnModel.getFirstVisibleColumnIndex();
		}
		if (node) {
			this.focusCell(cellIndex);
		}
	},

	initKeyDown: function(el) {
		var kn = new Ext.KeyNav(el, {
			defaultEventAction: this.treegrid.enableEditing === false ? 'preventDefault' : 'stopEvent',

			"left": function(e) {
				this.focusLeft(e);
			},

			"right": function(e) {
				this.focusRight(e);
			},

			"up": function(e) {
				e.stopEvent();
				var activeNode = this.selectPrevious(e);
				this.setActiveNode(activeNode || this.activeNode);
			},

			"down": function(e) {
				e.stopEvent();
				var activeNode = this.selectNext(e);
				this.setActiveNode(activeNode || this.activeNode);
			},

			"f2": function(e) {
				if (this.treegrid.enableEditing) {
					this.treegrid.editSelectedCell();
				}
			},
			"insert": function(e) {
				if (this.treegrid.enableEditing) {
					this.treegrid.insertRow(true);
				}
			},
			"del": function(e) {
				if (this.treegrid.enableEditing) {
					this.treegrid.removeSelectedRows();
				}
			},
			"c": function(e) {
				if (e.ctrlKey && e.altKey) {
					this.selectCurrentCellValue();
				}
			},
			"q": function(e) {
				quickFilter = this.getQuickFilter();
				if (!quickFilter) {
					return;
				}
				if (e.ctrlKey) {
					quickFilter.showEditWindow();
				} else {
					quickFilter.addSelectedValueFilter();
				}
			},
			"esc": function(e){
				this.clearDomSelection();
				if (this.treegrid.enableEditing) {
					this.treegrid.revertActiveRow();
				}
				return true;
			},
			scope: this,
			forceKeyDown: true
		});
		
	},
	
	getQuickFilter: function(){
		if (!this.treegrid.bottomToolbar) {
			return null;
		}
		return this.treegrid.bottomToolbar.items.get("quickFilter");
	},
	
	focusRight: function(e) {
		e.preventDefault();
		var activeNode = this.activeNode;
		if (activeNode.hasChildNodes()) {
			if (!activeNode.isExpanded()) {
				activeNode.expand();
			} else if (activeNode.firstChild) {
				this.select(activeNode.firstChild);
			}
		}
	},
	
	focusLeft: function(e, s) {
		e.preventDefault();
		var activeNode = this.activeNode;
		if (activeNode.hasChildNodes() && activeNode.isExpanded()) {
			activeNode.collapse();
		} else if (activeNode.parentNode && (activeNode.parentNode != this.treegrid.getRootNode())) {
			this.select(activeNode.parentNode);
		}
	},
	
	isSelected: function(node) {
		return this.selMap[node.id] ? true : false;
	},
	
	clearSelNodes: function(suppressEvents) {
		this.selData = [];
		this.selNodes = [];
		this.selMap = {};
		if (!suppressEvents) {
			this.treegrid.dataSource.clearSelection(this.treegrid.id);
		}	
	},
	
	clearSelections: function(suppressEvent) {
	},
	
	onFocus: function(e){
		this.treegrid.el.addClass("x-tree-focused");
	},
	
	onBlur: function(e){
		this.treegrid.unFocus();
	},
	
	selectCurrentCellValue: function() {
		var view = this.treegrid.view;
		var colModel = this.treegrid.getColumnModel();
		var node = this.activeNode;
		var colPosition = colModel.getColumnPosition(this.activeCellIndex);
		var nodeTable = node.ui.elNode;
		var cell = Ext.get(nodeTable.rows[0].childNodes[colPosition]);
		var innerCell = cell.child('.x-treegrid-cell-inner');
		var valueNode = innerCell.child('.value');
		this.selectDomValue(valueNode.dom);
	},
	
	selectDomValue: function(dom) {
		if (Ext.isIE){
			var range = document.body.createTextRange();
			range.moveToElementText(dom);
			range.select();
		} else {
			var selection = window.getSelection();
			var range = document.createRange();
			range.selectNodeContents(dom);
			selection.addRange(range);
		}
	},
	
	clearDomSelection: function() {
		if (Ext.isIE && !Ext.isIE11) {
			document.selection.empty();
		} else {
			var selection = window.getSelection();
			selection.removeAllRanges();
		}
	}
});

Terrasoft.treegrid.SingleRowSelectionModel = Ext.extend(Terrasoft.treegrid.AbstractSelectionModel, {

	onNodeClick: function(node, e) {
		if (node.isPaging) {
			return;
		}
		var view = this.treegrid.view;
		var target = Ext.lib.Event.getTarget(e);
		var cellIndex = view.findCellIndex(target);
		if ((node == this.activeNode) && (cellIndex == this.activeCellIndex) && (e.button == 0)) {
			this.treegrid.editSelectedCell(true);
		} else {
			this.treegrid.focus();
			this.select(node, false);
			this.setActiveNode(node, cellIndex);
		}
	},

	select: function(node, keepExisting, suppressEvents) {
		var treegrid = this.treegrid;
		if (treegrid.isTreeMode()) {
			node.parentNode.expandAllParents();
		}
		var dataSource = treegrid.dataSource;
		var row = dataSource.getRow(node.id);
		var isSelected = this.isSelected(node);
		if (isSelected && (keepExisting || (this.selData.length == 1))) {
			if (this.selData.length > 1) {
				this.unselect(node, suppressEvents);
			} else {
				return this.selNodes[0];
			}
		} else {
			if ((keepExisting !== true) || (this.activeNode && (node.parentNode != this.activeNode.parentNode) && !treegrid.allowCustomSelection)) {
				this.clearSelections(true);
			}
			this.selData.push(row.columns);
			this.selNodes.push(node);
			this.selMap[node.id] = node;
			node.ui.onSelectedChange(true);
			if (treegrid.enableEditing && dataSource.hasChanges()) {
				treegrid.dataSource.save();
			}
		}
		if (treegrid.hField) {
			treegrid.hField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData, 2);
		}
		if (!suppressEvents && (!isSelected || !keepExisting)) {
			dataSource.addToSelection(node.id, keepExisting, treegrid.id);
		}
		var rowValues = Ext.encode(row.columns, 2);
		treegrid.fireEvent("selectionchange", rowValues);
		return node;
	},

	focusRight: function(e) {
		e.preventDefault();
		var columnModel = this.treegrid.getColumnModel();
		var colIndex = columnModel.getNextVisibleColumnIndex(this.activeCellIndex);
		if (colIndex == null) {
			return;
		}
		this.blurActiveCell();
		this.focusCell(colIndex);
	},

	focusLeft: function(e) {
		e.preventDefault();
		var columnModel = this.treegrid.getColumnModel();
		var colIndex = columnModel.getPreviousVisibleColumnIndex(this.activeCellIndex);
		if (colIndex == null) {
			return;
		}
		this.blurActiveCell();
		this.focusCell(colIndex);
	},

	unselect: function(node, suppressEvents) {
		if (this.selMap[node.id]) {
			node.ui.onSelectedChange(false);
			var selData = this.selData;
			var treegrid = node.getTreeGrid();
			if (treegrid != undefined) {
				var primaryColumnName = treegrid.dataSource.structure.primaryColumnName;
				var index = this.getSelDataIndexByKeyValue(selData, primaryColumnName, node.id);
				if (index != -1) {
					selData.splice(index, 1);
					this.treegrid.hField.dom.value = Ext.util.JSON.encodeNamedArray(selData, 2);
					this.selNodes.splice(index, 1);
				}
			}
			delete this.selMap[node.id];
			var dataSource = treegrid.dataSource;
			if (!suppressEvents) {
				dataSource.removeFromSelection(node.id, treegrid.id);
				this.fireEvent("selectionchange", selData);
			}	
		}
	},

	getSelDataIndexByKeyValue: function(selData, keyName, keyValue) {
		for (var i = 0, count = selData.length; i < count; i++) {
			if (selData[i][keyName] == keyValue) {
				return i;
			}
		}
		return -1;
	},

	clearSelections: function(suppressEvent) {
		var node = this.selNodes[0];
		if (node) {
			this.unselect(node, suppressEvent);
		}
	},

	focusCell: function(colIndex) {
		if (colIndex == null) {
			return;
		}
		var columnModel = this.treegrid.getColumnModel();
		var colPosition = columnModel.getColumnPosition(colIndex);
		var nodeTable = this.activeNode.ui.elNode;
		var cell = Ext.get(nodeTable.rows[0].childNodes[colPosition]);
		cell.addClass("x-tree-cell-selected");
		this.treegrid.view.scrollTo(cell.dom);
		this.activeCellIndex = colIndex;
	},

	blurActiveCell: function() {
		var columnModel = this.treegrid.getColumnModel();
		var colIndex = this.activeCellIndex;
		if (colIndex != null) {
			this.clearDomSelection();
			var colPosition = columnModel.getColumnPosition(colIndex);
			var activeNode = this.activeNode;
			if (activeNode) {
				var nodeTable = activeNode.ui.elNode;
				var cell = Ext.get(nodeTable.rows[0].childNodes[colPosition]);
				if (cell) {
					cell.removeClass("x-tree-cell-selected");
				}
			}	
		}
	},
	
	getSelectedNodesSortedByPosition: function() {
		var selectedRows = this.selNodes;
		var ids = new Array();
		if (selectedRows.length > 0) {
			for (var i=0; i<selectedRows.length; i++) {
				var row = selectedRows[i];
				var index = row.parentNode.indexOf(row);
				var item = {
					node: row,
					index: index
				};
				ids.push(item);
			}
		}
		var sortFunction = function(a, b) {
				return (a.index < b.index ? -1 : 1);
		};
		ids.sort(sortFunction);
		return ids;
	},
	
	updateSelData: function(nodeId) {
		var dataSource = this.treegrid.dataSource;
		var selData = this.selData;
		var primaryColumnName = dataSource.getPrimaryColumnName();
		for (var i=0; i<selData.length; i++) {
			var item = selData[i];
			if (item[primaryColumnName] == nodeId) {
				var row = dataSource.getRow(nodeId);
				selData[i] = row.columns;
				var hField = this.treegrid.hField;
				if (hField) {
					hField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData, 2);
				}
				return;
			}
		}
	} 
});

Terrasoft.treegrid.MultiRowsSelectionModel = Ext.extend(Terrasoft.treegrid.SingleRowSelectionModel, {

	onNodeClick: function(node, e) {
		if (node.isPaging) {
			return;
		}
		var editing = this.treegrid.editing;
		var view = this.treegrid.view;
		var target = Ext.lib.Event.getTarget(e);
		var cellIndex = view.findCellIndex(target);
		if ((node == this.activeNode) && (cellIndex == this.activeCellIndex) && editing) {
			this.treegrid.activeEditor.field.focus();
			return;
		} else { 
			this.treegrid.stopEditing(false);
			this.treegrid.focus();
		}
		if (e.shiftKey) {
			var firstNode = this.activeNode;
			if ((!firstNode) || (firstNode.parentNode != node.parentNode)) {
				this.select(node, false);
			} else {
				this.clearSelections();
				this.selectNodesRange(firstNode, node, e);
			}
		} else {
			if (!e.ctrlKey && (node == this.activeNode) && (cellIndex == this.activeCellIndex) && (e.button == 0)
				&& node.isSelected() && this.treegrid.enableEditing) {
				this.treegrid.editSelectedCell(true);
			} else {
				if (e.target.tagName == "A") {
					return;
				}
				var activeNode = this.activeNode;
				var ctrlKey = (e.ctrlKey === true);
				this.select(node, ctrlKey);
				if (!e.ctrlKey && (node == activeNode)) {
					if (editing && (e.button == 0)) {
						this.blurActiveCell();
						this.focusCell(cellIndex);
						this.treegrid.editSelectedCell(true);
						return;
					}
				}
			}
		}
		this.setActiveNode(node, cellIndex);
	},
	
	clearSelections: function(suppressEvent) {
		var sn = this.selNodes;
		if (sn.length > 0) {
			for (var i = 0, len = sn.length; i < len; i++) {
				sn[i].ui.onSelectedChange(false);
			}
			this.clearSelNodes(suppressEvent);
			this.treegrid.hField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData, 2);
			if (suppressEvent !== true) {
				this.fireEvent("selectionchange", this.selData);
			}
		}	
	},
	
	selectNodesRange: function(firstNode, lastNode, e){
		var isUpDirection = false;
		if (firstNode.isElderSibling(lastNode)){
			isUpDirection = true;
		}
		this.treegrid.suspendEvents();
		try {
			this.selectNodes(firstNode, lastNode, e, isUpDirection);
		} finally {
			this.treegrid.resumeEvents();
			this.treegrid.fireEvent("selectionchange", "");
		}	
	},
	
	selectNodes: function(node, endNode, e, isUpDirection) {
		this.select(node, true);
		var nextNode;
		if (isUpDirection) {
			nextNode = node.previousSibling;
		} else {
			nextNode = node.nextSibling;
		}
		if ((nextNode) && (node != endNode)){
			this.selectNodes(nextNode, endNode, e, isUpDirection);
		}
	},
	
	selectAllVisibleChilds: function(node){
		if ((node.rendered) && (node.expanded)) {
			var childNode;
			for (var i=0, count=node.childNodes.length; i<count; i++){
				childNode = node.childNodes[i];
				if (childNode.rendered){
					this.select(childNode, true);
				}
			}
		}
	},
	
	selectAllVisibleNodes: function(){
		var treegrid = this.treegrid;
		if (treegrid.dataSource.rows.length == 0) {
			return;
		}
		treegrid.suspendEvents();
		var parentNode = this.activeNode ? this.activeNode.parentNode : treegrid.root;
		try {
			this.clearSelections(true);
			this.selectAllVisibleChilds(parentNode);
		} finally {
			treegrid.resumeEvents();
			treegrid.fireEvent("selectionchange", "");
		}
	}
});

if (Ext.dd.DropZone) {
	Ext.treegrid.TreeDropZone = function(treegrid, config) {
		this.allowParentInsert = false;
		this.allowContainerDrop = false;
		this.appendOnly = false;
		Ext.treegrid.TreeDropZone.superclass.constructor.call(this, treegrid.innerCt, config);
		this.treegrid = treegrid;
		this.dragOverData = {};
		this.lastInsertClass = "x-tree-no-status";
	};

	Ext.extend(Ext.treegrid.TreeDropZone, Ext.dd.DropZone, {
		ddGroup: "TreeDD",
		expandDelay: 1000,
		enableInnerDragDrop: false,
		dragDropMode: "Normal",

		getTargetFromEvent: function(e) {
			var treegrid = this.treegrid;
			var node = treegrid.eventModel.getNode(e);
			if (node) {
				var scrollWrapper = this.treegrid.view.scroller.dom.firstChild;
				if (scrollWrapper.needToScrollElement(node.ui.elNode)) {
					node = null;
				}
		 } else {
				if (!treegrid.view.scrollBar.vScroll.isVisible()) {
					var root = this.treegrid.root;
					if (root.lastChild) {
						node = root.lastChild;
					} else {
						node = root;
					}	
				}
			}
			return node ? {node:node,ddel:node.ui.elNode} : null;
		},

		expandNode: function(node) {
			if (node.isExpandable() && !node.isExpanded()) {
				node.expand(false, null, this.triggerCacheRefresh.createDelegate(this));
			}
		},

		queueExpand: function(node) {
			this.expandProcId = this.expandNode.defer(this.expandDelay, this, [node]);
		},

		cancelExpand: function() {
			if (this.expandProcId) {
				clearTimeout(this.expandProcId);
				this.expandProcId = false;
			}
		},

		isValidDropPoint: function(n, pt, dd, e, data) {
			if (!n || !data) {
				return false;
			}
			var targetNode = n.node;
			if (!(targetNode && targetNode.isTarget && pt)) {
				return false;
			}
			if (pt == "Append" && targetNode.allowChildren === false) {
				return false;
			}
			if ((pt == "Above" || pt == "Below") && (targetNode.parentNode && targetNode.parentNode.allowChildren === false)) {
				return false;
			}
			var dropNodes = data.nodes;
			for (var i = 0; i < dropNodes.length; i++) {
				var dropNode = dropNodes[i];
				if (dropNode && (targetNode == dropNode || dropNode.contains(targetNode))) {
					return false;
				}
			}
			var handler = this.treegrid.events["nodedragover"];
			if (handler && (typeof handler == "object")) {
				var overEvent = this.dragOverData;
				overEvent.treegrid = this.treegrid;
				overEvent.target = targetNode;
				overEvent.data = data;
				overEvent.point = pt;
				overEvent.source = dd;
				overEvent.rawEvent = e;
				overEvent.dropNodes = dropNodes;
				overEvent.cancel = this.treegrid.dropAllowed;
				var result = this.treegrid.fireEvent("nodedragover", overEvent);
				return overEvent.cancel !== true && result !== false;
			} else {
					if ((this.dragDropMode == "Append") && (pt != "Append")) {
						return false;
					}
					var allowDropNode = targetNode;
					if ((pt == "Above" || pt == "Below")) {
						allowDropNode = targetNode.parentNode;
					}
					return this.allowDropByConfigs(allowDropNode, data);
			}
		},

		getDropPoint: function(e, n, dd) {
			var tn = n.node;
			if (tn.isRoot) {
				return tn.allowChildren !== false ? "Append" : false;
			}
			var rootNode = tn.treegrid.root;
			var dragEl = n.ddel;
			var t = Ext.lib.Dom.getY(dragEl), b = t + dragEl.offsetHeight;
			var y = Ext.lib.Event.getPageY(e);
			var noAppend = tn.allowChildren === false;
			if (this.appendOnly && tn.parentNode.allowChildren === false) {
				return noAppend ? false : "Append";
			}
			var noBelow = false;
			if (!this.allowParentInsert) {
				noBelow = tn.hasChildNodes() && tn.isExpanded();
			}
			var q = (b - t) / (noAppend ? 2 : 3);
			if (y >= t && y < (t + q)) {
				return "Above";
			} else if (!noBelow && (noAppend || (y >= b - q && y <= b) || (y > b && tn == rootNode.lastChild))) {
				return "Below";
			} else {
				return "Append";
			}
		},

		onNodeEnter: function(n, dd, e, data) {
			this.cancelExpand();
		},
		
		isInnerDragDrop: function(dragData) {
			var dragTreegrid = dragData.nodes[0].getTreeGrid();
			return (this.treegrid == dragTreegrid);
		},
		
		allowDropByConfigs: function(node, dragData) {
			var dropNodeConfig = this.getNodeConfig(node);
			if (dropNodeConfig && dropNodeConfig.dropTags) {
				var dropTags = dropNodeConfig.dropTags;
				var dragNodes = dragData.nodes;
				for (var i=0; i<dragNodes.length; i++) {
					var dragNode = dragNodes[i];
					var dragNodeConfig = this.getNodeConfig(dragNode);
					var isCompatible = dragNodeConfig && dragNodeConfig.dragTags && this.hasCompatibleTags(dropTags, dragNodeConfig.dragTags);
					if (!isCompatible) {
						return false;
					}
				}
				return true;
			}
			return false;
		},
		
		getNodeConfig: function(node) {
			var id = node.id;
			if (node.isRoot) {
				return {dropTags: new Array('Root')};
			}
			var treegrid = node.getTreeGrid();
			if (treegrid.configs && treegrid.configs[id]) {
				return treegrid.configs[id];
			} else {
				return null;
			}
		},
		
		hasCompatibleTags: function(dropTags, dragTags) {
			for (var i=0; i<dragTags.length; i++) {
				var dragTag = dragTags[i];
				if (dropTags.indexOf(dragTag) > -1) {
					return true;
				}
			}
			return false;
		}, 

		onNodeOver: function(n, dd, e, data) {
			if (this.isInnerDragDrop(data) && !this.enableInnerDragDrop) {
				return this.dropNotAllowed;
			}
			var node = n.node;
			var pt = this.getDropPoint(e, n, dd);
			if (!this.expandProcId && pt == "Append" && node.hasChildNodes() && !n.node.isExpanded()) {
				this.queueExpand(node);
			} else if (pt != "Append") {
				this.cancelExpand();
			}
			var returnCls = this.dropNotAllowed;
			if (this.isValidDropPoint(n, pt, dd, e, data)) {
				if (pt) {
					var el = n.ddel;
					var cls;
					if (pt == "Above") {
						returnCls = n.node.isFirst() ? "x-tree-drop-ok-above" : "x-tree-drop-ok-between";
						cls = "x-tree-drag-insert-above";
					} else if (pt == "Below") {
						returnCls = n.node.isLast() ? "x-tree-drop-ok-below" : "x-tree-drop-ok-between";
						cls = "x-tree-drag-insert-below";
					} else {
						returnCls = "x-tree-drop-ok-append";
						cls = "x-tree-drag-append";
					}
					if (this.lastInsertClass != cls) {
						if (el) {
							Ext.fly(el).replaceClass(this.lastInsertClass, cls);
							this.lastInsertClass = cls;
						}	
					}
				}
			}
			return returnCls;
		},

		onNodeOut: function(n, dd, e, data) {
			this.cancelExpand();
			this.removeDropIndicators(n);
		},

		onNodeDrop: function(n, dd, e, data) {
			if (data.nodes.length == 0) {
				return false;
			}
			var failureInnerDragDrop = this.isInnerDragDrop(data) && !this.enableInnerDragDrop;
			if (failureInnerDragDrop || !dd.proxy.isVisible || dd.proxy.dropStatus == dd.dropNotAllowed) {
				return false;
			}
			var point = this.getDropPoint(e, n, dd);
			var targetNode = n.node;
			targetNode.ui.startDrop();
			if (!this.isValidDropPoint(n, point, dd, e, data)) {
				targetNode.ui.endDrop();
				return false;
			}
			var dropNodes = data.nodes;
			var dropEvent = {
				treegrid: this.treegrid,
				target: targetNode,
				data: data,
				point: point,
				source: dd,
				rawEvent: e,
				dropNodes: dropNodes,
				cancel: !dropNodes,
				dropStatus: false,
				customDrop: false
			};
			var retval = this.treegrid.fireEvent("beforenodesdrop", dropEvent);
			if (retval === false || dropEvent.cancel === true || !dropEvent.dropNodes) {
				targetNode.ui.endDrop();
				return dropEvent.dropStatus;
			}
			targetNode = dropEvent.target;
			this.completeDrop(dropEvent);
			return true;
		},

		completeDrop: function(de) {
			var ns = de.dropNodes, p = de.point, t = de.target;
			if (!Ext.isArray(ns)){
				ns = [ns];
			}
			var n;
			var nodes = [];
			var len = ns.length;
			var updateNode = (p == "Append") ? t : t.parentNode;
			var customDrop = de.customDrop;
			var dropTreeGrid = ns[0].getTreeGrid();
			var dropDataSource = dropTreeGrid.dataSource;
			this.treegrid.suspendEvents();
			try {
				for (var i = 0; i < len; i++) {
					n = ns[i];
					var row = dropDataSource.getRow(n.id);
					nodes.push(row.columns);
				}
				t.ui.endDrop();
			} finally {
				this.treegrid.resumeEvents();
			}
			
			var encodedNodes = Ext.encode(nodes);
			var parentRow = dropDataSource.getRow(n.parentNode.id);
			var encodedParentNode = n.parentNode.isRoot ? '' : Ext.encode(parentRow.columns);
			var encodedTarget = Ext.encode(t.id);
			if (!t.isRoot) {
				var targetRow = this.treegrid.dataSource.getRow(t.id);
				encodedTarget = Ext.encode(targetRow.columns);
			}
			var handler = this.treegrid.events["nodesdrop"];
			if (handler && (typeof handler == "object")) {
				this.treegrid.fireEvent("nodesdrop", encodedNodes, encodedTarget, encodedParentNode, p);
			} else {
				this.treegrid.selModel.clearSelections();
				var ids = new Array();
				if (p == "Below") {
					for (var i=ns.length-1; i>=0; i--) {
						var node = ns[i];
						this.treegrid.dataSource.move(node.id, t.id, p);
						ids.push(node.id);
					}
				} else {
					for (var i=0; i<ns.length; i++) {
						var node = ns[i];
						this.treegrid.dataSource.move(node.id, t.id, p);
						ids.push(node.id);
					}
				}
				this.treegrid.selectNodes(ids, false, true);	
			}	
		},

		getTree: function() {
			return this.treegrid;
		},

		removeDropIndicators: function(n) {
			if (n && n.ddel) {
				var el = n.ddel;
				Ext.fly(el).removeClass([
						"x-tree-drag-insert-above",
						"x-tree-drag-insert-below",
						"x-tree-drag-append"]);
				this.lastInsertClass = "_noclass";
			}
		},

		beforeDragDrop: function(target, e, id) {
			this.cancelExpand();
			return true;
		},

		afterRepair: function(data) {
			if (data && Ext.enableFx) {
				for (var i = 0; i < data.nodes.length; i++) {
					data.nodes[i].ui.highlight();
				}
			}
			this.hideProxy();
		},
		
		isTargetVisible: function(e) {
			var target = this.getTargetFromEvent(e);
			return !Ext.isEmpty(target);	
		},

		notifyOut: function(dd, e, data) {
			var dropNodes = data.nodes;
			var handler = this.treegrid.events["notifyout"];
			if (handler && (typeof handler == "object")) {
				var overEvent = this.dragOverData;
				overEvent.treegrid = this.treegrid;
				overEvent.data = data;
				overEvent.source = dd;
				overEvent.rawEvent = e;
				overEvent.dropNodes = dropNodes;
				var result = this.treegrid.fireEvent("notifyout", overEvent);
			}
		}
	});
}

if (Ext.dd.DragZone) {
	Ext.treegrid.TreeDragZone = function(treegrid, config) {
		Ext.treegrid.TreeDragZone.superclass.constructor.call(this, treegrid.view.el, config);
		this.treegrid = treegrid;
	};

	Ext.extend(Ext.treegrid.TreeDragZone, Ext.dd.DragZone, {
		ddGroup: "TreeDD",

		handleMouseDown: function(e) {
			if (this.dragging || e.altKey) {
				return;
			}
			Ext.treegrid.TreeDragZone.superclass.handleMouseDown.apply(this, arguments);
			var node = this.treegrid.eventModel.getNode(e);
			this.treegrid.eventModel.skipEvent = false;
			if (node && !node.isSelected() && !node.isPaging){
				this.treegrid.eventModel.delegateClick(e, e.target);
				this.dragData = this.getDragData(e);
				this.treegrid.eventModel.skipEvent = true;
			}
		},

		getDragData: function(e) {
			var treegrid = this.treegrid;
			var dataSource = treegrid.dataSource;
			var selNodes = treegrid.selModel.selNodes;
			var selNodes = treegrid.selModel.getSelectedNodesSortedByPosition();
			var rows = new Array();
			for (var i=0, count=selNodes.length; i<count; i++) {
				var node = selNodes[i].node;
				var row = dataSource.getRow(node.id);
				if (row) {
					node.row = row.columns;
					rows.push(node);
				}	
			}
			return {nodes: rows};
		},

		onInitDrag: function(x, y) {
			var e = this.DDM.e;
			if (e) {
				var node = this.treegrid.eventModel.getNode(e);
				if (!node) {
					return false;
				}
				var data = this.dragData;
				if (data.nodes && data.nodes.length == 0) {
					return false;
				}
				for (var i = 0; i < data.nodes.length; i++) {
					var node = data.nodes[i];
					if (!node.draggable || node.disabled) {
						return false;
					}
				}
				var treegrid = this.treegrid;
				var selModel = treegrid.getSelectionModel();
				treegrid.eventModel.disable();
				var proxyInfo;
				if (data.nodes.length > 1){
					proxyInfo = this.getMultiSelectInfo(data.nodes);
				} else {
					proxyInfo = this.getSingleNodeInfo(data.nodes[0]);
				}
				var template = new Ext.Template(
					'<table cellspacing="0">',
						'<tr>',
							!Ext.isEmpty(proxyInfo.icon) ? '{icon}' : '',
							'<td>{proxyCaption}</td>',
						'</tr>',
					'</table>'
				);
				var proxyHtml = template.apply(proxyInfo);
				this.proxy.update(proxyHtml);
				treegrid.fireEvent("startdrag", this.treegrid, data.nodes, e);
				return true;
			}	
			return false;
		},
		
		getMultiSelectInfo: function(nodes){
			var template = "{0}: {1}";
			var message = Ext.StringList('WC.TreeGrid').getValue('DragAndDrop.RecordCount');
			var nodeCount = nodes.length;
			var info = new Object();
			info.proxyCaption = String.format(template, message, nodeCount);
			return info;
		},
		
		getSingleNodeInfo: function(node){
			var colModel = this.treegrid.getColumnModel();
			var dataSource = this.treegrid.dataSource;
			var displayColumn = dataSource.structure.primaryDisplayColumnName;
			var column = colModel.getColumnByName(displayColumn);
			var caption = "";
			if ((column) && (column.isVisible)){
				caption = dataSource.getValue(node.id, displayColumn);
			} else {
				column = colModel.getFirstVisibleColumn();
				if (column){
					caption = dataSource.getValue(node.id, column.name);;
				}	
			}
			var info = new Object();
			info.proxyCaption = caption;
			info.icon = this.getColumnIcons(node, column);
			return info;
		},
		
		getColumnIcons: function(node, column){
			var iconClass = ".x-treegrid-cell-icon";
			var colModel = this.treegrid.getColumnModel();
			var colIndex = colModel.getIndexByName(column.name);
			var colPosition = colModel.getColumnPosition(colIndex);
			var nodeTable = node.ui.elNode;
			var cell = Ext.get(nodeTable.rows[0].childNodes[colPosition]);
			var iconImage = "";
			var cellIcon = cell.child(iconClass);
			while (cellIcon) {
				if (cellIcon.dom.outerHTML) {
					iconImage += cellIcon.dom.outerHTML;
				} else {
					iconImage += this.getNodeOuterHTML(cellIcon.dom);
				}
				cellIcon = cellIcon.next(iconClass);
			}
			return iconImage;	
		},
		
		getNodeOuterHTML: function(el){
			var emptyTags = {
				"IMG": true,
				"BR": true,
				"INPUT": true,
				"META": true,
				"LINK": true,
				"PARAM": true,
				"HR": true
			};
			var attrs = el.attributes;
			var str = "<" + el.tagName;
			for (var i = 0; i < attrs.length; i++) {
				str += " " + attrs[i].name + "=\"" + attrs[i].value + "\"";
			}
			if (emptyTags[el.tagName]) {
				return str + ">";
			}
			return str + ">" + el.innerHTML + "</" + el.tagName + ">";
		},

		getRepairXY: function(e, data) {
			var node = data.nodes[0];
			return node && node.ui.getDDRepairXY();
		},

		onEndDrag: function(data, e) {
			this.treegrid.eventModel.enable.defer(100, this.treegrid.eventModel);
			this.treegrid.fireEvent("enddrag", this.treegrid, data.nodes, e);
		},

		onValidDrop: function(dd, e, id) {
			this.treegrid.fireEvent("dragdrop", this.treegrid, this.dragData.nodes, dd, e);
			this.hideProxy();
		},

		afterRepair: function() {
			this.dragging = false;
		}
	});
}

Ext.treegrid.TreeEditor = function(treegrid, fc, config) {
	fc = fc || {};
	var field = fc.events ? fc : new Ext.form.TextField(fc);
	Ext.treegrid.TreeEditor.superclass.constructor.call(this, field, config);
	this.treegrid = treegrid;
	if (!treegrid.rendered) {
		treegrid.on('render', this.initEditor, this);
	} else {
		this.initEditor(treegrid);
	}
};

Ext.extend(Ext.treegrid.TreeEditor, Ext.Editor, {
	alignment: "tl",
	autoSize: "width",
	hideEl: false,
	cls: "x-small-editor x-treegrid-editor",
	shim: false,
	shadow: false,
	autoScroll: false,
	calcXOffsets: false,
	maxWidth: 250,
	editDelay: 350,

	initEditor: function(treegrid) {
		treegrid.on('dblclick', this.onNodeDblClick, this);
		this.on('complete', this.updateNode, this);
		this.on('beforestartedit', this.fitToTree, this);
		this.on('specialkey', this.onSpecialKey, this);
	},

	fitToTree: function(ed, el) {
		var td = this.treegrid.getTreeEl().dom, nd = el.dom;
		var w = Math.min(
				this.maxWidth,
				(td.clientWidth > 20 ? td.clientWidth : td.offsetWidth) - Math.max(0, nd.offsetLeft - td.scrollLeft) - 5);
		this.setSize(w, '');
	},

	triggerEdit: function(node, defer) {
		this.completeEdit();
		if (node.attributes.editable !== false) {
			this.editNode = node;
			if (this.autoScroll) {
				node.ui.getEl().scrollIntoView(this.treegrid.body);
			}
			this.autoEditTimer = this.startEdit.defer(this.editDelay, this, [node.ui.textNode, node.text]);
			return false;
		}
	},

	onNodeDblClick: function(node, e) {
		clearTimeout(this.autoEditTimer);
	},

	updateNode: function(ed, value) {
		
	},

	onHide: function() {
		Ext.treegrid.TreeEditor.superclass.onHide.call(this);
		if (this.editNode) {
			this.editNode.ui.focus.defer(50, this.editNode.ui);
		}
	},

	onSpecialKey: function(field, e) {
		var k = e.getKey();
		if (k == e.ESC) {
			e.stopEvent();
			this.cancelEdit();
		} else if (k == e.ENTER && !e.hasModifier()) {
			e.stopEvent();
			this.completeEdit();
			if (this.treegrid.editedNode){
				this.treegrid.editNextColumn();
			}
		} else if (k == e.TAB && !e.hasModifier()) {
			e.stopEvent();
			this.completeEdit();
			this.treegrid.editNextColumn();
		} else if (k == e.TAB && e.hasModifier() && e.shiftKey) {
			e.stopEvent();
			this.completeEdit();
			this.treegrid.editPreviousColumn();
		}  
	}
});

Ext.treegrid.ColumnModel = function(config) {
	this.defaultWidth = 80;
	this.defaultSortable = true;

	if (config.columns) {
		Ext.apply(this, config);
		this.setConfig(config.columns, true);
	} else {
		this.setConfig(config, true);
	}
	this.addEvents(
		"widthchange",
		"headerchange",
		"hiddenchange",
		"columnmoved",
		"columnlockchange",
		"configchange"
	);
	Ext.treegrid.ColumnModel.superclass.constructor.call(this);
};

Ext.extend(Ext.treegrid.ColumnModel, Ext.util.Observable, {

	setConfig: function(config, initial) {
		if (!initial) {
			delete this.totalWidth;
		}
		this.config = config;
		for (var i = 0, len = config.length; i < len; i++) {
			var c = config[i];
			this.config[i].isVisible = c.isVisible !== false;
			this.config[i].isAlwaysSelect = c.isAlwaysSelect == true;
			this.config[i].isLookup = c.refSchemaName != null;
			this.config[i].sortable = c.sortable !== false;
			if (typeof c.renderer == "string") {
				c.renderer = Ext.util.Format[c.renderer];
			}
			if (typeof c.name == "undefined") {
				c.name = i;
			}
		}
		delete this.columns;
		if (!initial) {
			this.fireEvent('configchange', this);
		}
	},

	getColumnByName: function(name) {
		for (var i = 0, len = this.config.length; i < len; i++) {
			if (this.config[i].name == name) {
				return this.config[i];
			}
		}
		return null;
	},
	
	getColumnByUId: function(uId) {
		for (var i = 0, len = this.config.length; i < len; i++) {
			if (this.config[i].uId == uId) {
				return this.config[i];
			}
		}
		return null;
	},
	
	getColumnByMetaPath: function(metaPath) {
		for (var i = 0, len = this.config.length; i < len; i++) {
			if (this.config[i].metaPath == metaPath) {
				return this.config[i];
			}
		}
		return null;
	},

	getColumn: function(index) {
		return this.config[index];
	},

	getIndexByName: function(name) {
		for (var i = 0, len = this.config.length; i < len; i++) {
			if (this.config[i].name == name) {
				return i;
			}
		}
		return -1;
	},

	moveColumn: function(oldIndex, newIndex) {
		var column = this.config[oldIndex];
		this.dataMap = null;
		this.fireEvent("columnmoved", column.uId, newIndex);
	},

	isLocked: function(colIndex) {
		return this.config[colIndex].locked === true;
	},

	setLocked: function(colIndex, value, suppressEvent) {
		if (this.isLocked(colIndex) == value) {
			return;
		}
		this.config[colIndex].locked = value;
		if (!suppressEvent) {
			this.fireEvent("columnlockchange", this, colIndex, value);
		}
	},

	getTotalLockedWidth: function() {
		var totalWidth = 0;
		for (var i = 0; i < this.config.length; i++) {
			if (this.isLocked(i) && this.isVisible(i)) {
				this.totalWidth += this.getColumnWidth(i);
			}
		}
		return totalWidth;
	},

	getLockedCount: function() {
		for (var i = 0, len = this.config.length; i < len; i++) {
			if (!this.isLocked(i)) {
				return i;
			}
		}
	},

	getColumnCount: function(visibleOnly) {
		if (visibleOnly === true) {
			var c = 0;
			for (var i = 0, len = this.config.length; i < len; i++) {
				if (this.isVisible(i)) {
					c++;
				}
			}
			return c;
		}
		return this.config.length;
	},

	getColumnsBy: function(fn, scope) {
		var r = [];
		for (var i = 0, len = this.config.length; i < len; i++) {
			var c = this.config[i];
			if (fn.call(scope || this, c, i) === true) {
				r[r.length] = c;
			}
		}
		return r;
	},

	isSortable: function(col) {
		if (typeof this.config[col].sortable == "undefined") {
			return this.defaultSortable;
		}
		return this.config[col].sortable;
	},

	isMenuDisabled: function(col) {
		return !!this.config[col].menuDisabled;
	},
	
	isSummaryMenuDisabled: function(col) {
		return !!this.config[col].summaryMenuDisabled;
	},
	
	enableSummaryMenu: function(col, enabled) {
		this.config[col].summaryMenuDisabled = !enabled;
	},

	getRenderer: function(col) {
		if (!this.config[col].renderer) {
			return Ext.treegrid.ColumnModel.defaultRenderer;
		}
		return this.config[col].renderer;
	},

	setRenderer: function(col, fn) {
		this.config[col].renderer = fn;
	},

	getColumnWidth: function(col) {
		return this.config[col].width || this.defaultWidth;
	},

	setColumnWidth: function(col, width, suppressEvent) {
		this.config[col].width = width;
		this.totalWidth = null;
		if (!suppressEvent) {
			this.fireEvent("widthchange", this, col, width);
		}
	},

	getTotalWidth: function(includeHidden) {
		if (!this.totalWidth) {
			this.totalWidth = 0;
			for (var i = 0, len = this.config.length; i < len; i++) {
				if (includeHidden || this.isVisible(i)) {
					this.totalWidth += this.getColumnWidth(i);
				}
			}
		}
		return this.totalWidth;
	},

	getColumnHeader: function(col) {
		return this.config[col].caption;
	},

	setColumnHeader: function(col, header) {
		this.config[col].caption = header;
		this.fireEvent("headerchange", this, col, header);
	},

	getColumnName: function(col) {
		return this.config[col].name;
	},

	setColumnName: function(col, name) {
		this.config[col].name = name;
	},

	isCellEditable: function(colIndex) {
		return (this.config[colIndex].editable !== false);
	},

	getColumnEditor: function(node, colName) {
		var treeEditor = Ext.treegrid.TreeEditor;
		var treegrid = node.getTreeGrid();
		var column = this.getColumnByName(colName);
		var dataValueType = column.dataValueType;
		var xtype = dataValueType.editor.controlXType;
		var defaultConfiguration = this.getEditorConfig(dataValueType, treegrid.dataSource, colName);
		var editor = Ext.ComponentMgr.create(defaultConfiguration, xtype);
		this.subscribeEditorEvents(editor, xtype, treegrid);
		return new treeEditor(treegrid, editor);
	},
	
	subscribeEditorEvents: function(editor, xtype, treegrid) {
		switch(xtype) {
			case "lookupedit":
				var handler = function(lookupedit) {
					var dataSource = lookupedit.dataSource;
					var activeRow = dataSource.activeRow;
					var row = Ext.encode(activeRow.columns);
					var columnName = Ext.encode(lookupedit.columnName);
					var userContextUId = Ext.encode(lookupedit.userContextUId);
					treegrid.fireEvent("preparelookupfilter", row, columnName, userContextUId);
				};
				editor.on("preparelookupfilter", handler);
				break;
		}
	},
	
	getEditorConfig: function(dataValueType, dataSource, colName) {
		var defaultConfiguration = dataValueType.editor.defaultConfiguration;
		var config = Ext.isEmpty(defaultConfiguration) ? {} : Ext.decode(defaultConfiguration);
		config.selectOnFocus = true;
		var xtype = this.getEditorXType(dataValueType);
		switch (xtype) {
			case "lookupedit":
			case "combobox":
				config.dataSource = dataSource;
				config.columnName = colName;
				config.userContextUId = new Ext.ux.GUID().id;
				var id = Ext.id();
				config.id = id.replace(/-/g,'');
				break;
			case "checkbox":
				config.captionPosition = 'left';
				break;
			case "coloredit":
				config.displayMode = 'Both';
				break;
		}
		return config;
	},
	
	getEditorXType: function(dataValueType){
		return dataValueType.editor.controlXType;
	},
	
	setEditable: function(col, editable) {
		this.config[col].editable = editable;
	},

	isVisible: function(colIndex) {
		return this.config[colIndex].isVisible;
	},
	
	isLastVisibleColumn: function(colIndex){
		if (!this.isVisible(colIndex)){
			return false;
		}
		for (var i = colIndex+1, len = this.config.length; i < len; i++) {
			if (this.isVisible(i)) {
				return false;
			}
		}
		return true;
	},

	isFixed: function(colIndex) {
		return this.config[colIndex].fixed;
	},

	isAutoFit: function(colIndex) {
		return this.config[colIndex].autofit;
	},

	isResizable: function(colIndex) {
		return colIndex >= 0 && this.config[colIndex].resizable !== false && this.config[colIndex].fixed !== true;
	},

	setVisible: function(colIndex, isVisible) {
		var c = this.config[colIndex];
		if (c.isVisible !== isVisible) {
			this.totalWidth = null;
			this.fireEvent("hiddenchange", this, colIndex, isVisible);
		}
	},

	setEditor: function(col, editor) {
		this.config[col].editor = editor;
	},

	getColumnPosition: function(col) {
		var position = -1;
		for (var i = 0; i <= col; i++) {
			if (this.config[i].isVisible) {
				position++;
			}
		}
		return position;
	},

	getFirstVisibleColumn: function() {
		var column;
		for (var i = 0, count = this.config.length; i < count; i++) {
			column = this.config[i];
			if (column.isVisible) {
				return column;
			}
		}
		return null;
	},
	
	hasVisibleColumns: function() {
		return !Ext.isEmpty(this.getFirstVisibleColumn());
	}, 
	
	getFirstVisibleColumnIndex: function() {
		var column;
		for (var i = 0, count = this.config.length; i < count; i++) {
			column = this.config[i];
			if (column.isVisible) {
				return i;
			}
		}
		return null;
	}, 
	
	getNextVisibleColumnIndex: function(index) {
		var column;
		for (var i = index+1, count = this.config.length; i < count; i++) {
			column = this.config[i];
			if (column.isVisible) {
				return i;
			}
		}
		return null;
	},
	
	getPreviousVisibleColumnIndex: function(index) {
		var column;
		for (var i = index-1, count = this.config.length; i >= 0; i--) {
			column = this.config[i];
			if (column.isVisible) {
				return i;
			}
		}
		return null;
	},
	
	getFirstEditableColumnIndex: function(){
		var column;
		for (var i = 0, count = this.config.length; i < count; i++) {
			column = this.config[i];
			if (column.isVisible && this.isCellEditable(i)) {
				return i;
			}
		}
		return null;
	},
	
	getNextEditableColumnIndex: function(index) {
		var column;
		for (var i = index+1, count = this.config.length; i < count; i++) {
			column = this.config[i];
			if (column.isVisible && this.isCellEditable(i)) {
				return i;
			}
		}
		return null;
	},
	
	getPreviousEditableColumnIndex: function(index) {
		var column;
		for (var i = index-1, count = this.config.length; i >= 0; i--) {
			column = this.config[i];
			if (column.isVisible && this.isCellEditable(i)) {
				return i;
			}
		}
		return null;
	}

});

Ext.treegrid.ColumnModel.defaultRenderer = function(value) {
	if (typeof value == "string" && value.length < 1) {
		return "&#160;";
	}
	return value;
};

Ext.treegrid.DefaultColumnModel = Ext.treegrid.ColumnModel;

Ext.treegrid.GridView = function(config) {
	Ext.apply(this, config);
	this.addEvents(
		"beforerowremoved",
		"beforerowsinserted",
		"beforerefresh",
		"rowremoved",
		"rowsinserted",
		"rowupdated",
		"refresh",
		"dblclick"
	);
	Ext.treegrid.GridView.superclass.constructor.call(this);
};

Ext.extend(Ext.treegrid.GridView, Ext.util.Observable, {
	deferEmptyText: true,
	autoFill: false,
	sortClasses: ["sort-asc", "sort-desc"],
	columnPaddingSize: 5,
	tdClass: 'x-treegrid-cell',
	hdCls: 'x-treegrid-hd',
	emptySpaceClass: "empty-space",
	multilineClass: "multi-line",
	cellSelectorDepth: 8,
	rowSelectorDepth: 12,
	cellSelector: '.x-treegrid-cell',
	rowSelector: '.x-treegrid-row',
	columnSortingHash: {},

	initTemplates: function() {
		var ts = this.templates || {};
		if (!ts.master) {
			ts.master = new Ext.Template(
			'<div class="x-treegrid {hideRowBorders}" hidefocus="true">',
					'<div class="x-treegrid-viewport">',
						'<div class="x-treegrid-header"><div class="x-treegrid-header-inner"><div class="x-treegrid-header-offset">{header}</div></div><div class="x-clear"></div></div>',
						'<div class="x-treegrid-scroller {multilineClass}">',
							'<div class="x-treegrid-body"></div>',
							'<a href="#" class="x-treegrid-focus"></a>',
						'</div>',
						'<div class="x-treegrid-summary-row"></div>',
					'</div>',
					'<div class="x-treegrid-resize-marker">&#160;</div>',
					'<div class="x-treegrid-resize-proxy">&#160;</div>',
			'</div>'
			);
		}

		if (!ts.header) {
			ts.header = new Ext.Template(
				'<table border="0" cellspacing="0" cellpadding="0" style="{tstyle}" class="x-treegrid-header-table">',
					'<thead><tr class="x-treegrid-hd-row">{cells}</tr></thead>',
				'</table>'
			);
		}

		if (!ts.hcell) {
			ts.hcell = new Ext.Template(
				'<td class="x-treegrid-hd x-treegrid-cell x-treegrid-cell-{name} {orderDirectionClass} {lastColumn}" style="{style}">',
					'<div style="position:relative">',
					'<div {tooltip} {attr} class="x-treegrid-hd-inner x-treegrid-hd-{name}" style="{istyle}">',
						'<img class="x-treegrid-sort-icon" src="', Ext.BLANK_IMAGE_URL, '" />',
						'{value}<span class="sort-index">{sortIndex}</span>',
					'</div>',
						this.treegrid.enableHdMenu ? '<a class="x-treegrid-hd-btn" href="#"></a>' : '',
				'</div>',
				'</td>'
			);
		}

		if (!ts.body) {
			ts.body = new Ext.Template('{rows}');
		}

		ts.summary = '<div></div>';

		for (var k in ts) {
			var t = ts[k];
			if (t && typeof t.compile == 'function' && !t.compiled) {
				t.disableFormats = true;
				t.compile();
			}
		}

		this.templates = ts;
		this.colRe = new RegExp("x-treegrid-cell-([^\\s]+)", "");
	},

	fly: function(el) {
		if (!this._flyweight) {
			this._flyweight = new Ext.Element.Flyweight(document.body);
		}
		this._flyweight.dom = el;
		return this._flyweight;
	},

	getEditorParent: function() {
		return this.scroller.dom;
	},

	initElements: function() {
		var header = this.renderHeaders();
		var body = this.templates.body.apply({ rows: '' });
		var html = this.templates.master.apply({
			hideRowBorders: this.treegrid.hideRowBorders ? "hide-row-borders" : "",
			multilineClass: this.treegrid.isMultilineMode ? this.multilineClass : "",
			body: body,
			header: header
		});
		Ext.DomHelper.append(this.treegrid.getGridEl().dom, html);
		var E = Ext.Element;
		var el = this.treegrid.getGridEl().dom.firstChild;
		var cs = el.childNodes;
		this.el = new E(el);
		this.mainWrap = new E(cs[0]);
		this.mainHd = new E(this.mainWrap.dom.firstChild);
		if (this.treegrid.hideHeaders) {
			this.mainHd.setDisplayed(false);
		}
		this.innerHd = this.mainHd.dom.firstChild;
		this.scroller = new E(this.mainWrap.dom.childNodes[1]);
		var mainBody = new E(this.scroller.dom.firstChild);
		mainBody.on("dblclick", this.handleDblClick, this);
		this.scrollBar = Ext.ScrollBar.insertScrollBar(mainBody.id, { onScroll: this.syncScroll.createDelegate(this) });
		this.mainBody = this.scrollBar.contentWrap;
		this.summary = new E(this.mainWrap.dom.lastChild);
		this.focusEl = new E(this.scroller.dom.lastChild);
		this.focusEl.swallowEvent("click", true);
		this.resizeMarker = new E(cs[1]);
		this.resizeProxy = new E(cs[2]);
	},

	getRows: function() {
		if (this.rows) {
			return this.rows;
		}
		this.rows = [];
		this.fillRows(this.mainBody.dom);
		return this.rows;
	},

	fillRows: function(dom) {
		for (var i = 0; i < dom.childNodes.length; i++) {
			var node = dom.childNodes[i];
			if (!this.isEmptySpaceNode(node)) {
				this.rows.push(node);
				if (node.lastChild) {
					this.fillRows(node.lastChild);
				}
			}
		}
	},

	isEmptySpaceNode: function(node) {
		return node.className ? (node.className.indexOf(this.emptySpaceClass) != -1) : false;
	},

	getEmptySpaceNode: function() {
		var node = this.mainBody.child("div." + this.emptySpaceClass);
		if (node) {
			return node.dom;
		} else {
			return null;
		}
	},

	findCell: function(el) {
		if (!el) {
			return false;
		}
		return this.fly(el).findParent(this.cellSelector, this.cellSelectorDepth);
	},

	findCellIndex: function(el, requiredCls) {
		var cell = this.findCell(el);
		if (cell && (!requiredCls || this.fly(cell).hasClass(requiredCls))) {
			return this.getCellIndex(cell);
		}
		return null;
	},

	getCellIndex: function(el) {
		if (el) {
			var m = el.className.match(this.colRe);
			if (m && m[1]) {
				var colModel = this.treegrid.getColumnModel();
				return colModel.getIndexByName(m[1]);
			}
		}
		return null;
	},

	findHeaderCell: function(el) {
		var cell = this.findCell(el);
		return cell && this.fly(cell).hasClass(this.hdCls) ? cell : null;
	},

	findHeaderIndex: function(el) {
		return this.findCellIndex(el, this.hdCls);
	},

	findRow: function(el) {
		if (!el) {
			return false;
		}
		return this.fly(el).findParent(this.rowSelector, this.rowSelectorDepth);
	},

	getRow: function(row) {
		return this.getRows()[row];
	},

	getCell: function(row, col) {
		var row = Ext.get(this.getRow(row));
		var rowTable = row.child(".x-treegrid-row-table").dom;
		return rowTable.rows[0].cells[this.getColumnPosition(col)];
	},

	getHeaderCell: function(index) {
		return this.mainHd.dom.getElementsByTagName('td')[index];
	},

	addRowClass: function(row, cls) {
		var r = this.getRow(row);
		if (r) {
			this.fly(r).addClass(cls);
		}
	},

	removeRowClass: function(row, cls) {
		var r = this.getRow(row);
		if (r) {
			this.fly(r).removeClass(cls);
		}
	},

	removeRow: function(row) {
		Ext.removeNode(this.getRow(row));
		this.focusRow(row);
	},

	updateScroll: function() {
		var scrollBar = this.scrollBar;
		if (scrollBar) {
			var isVScrollVisible = scrollBar.vScroll.isVisible();
			var isHScrollVisible = scrollBar.hScroll.isVisible();
			var scrollConfig = this.getScrollConfig();
			scrollBar.update(scrollConfig);
			if (isVScrollVisible != scrollBar.vScroll.isVisible()) {
				delete this.lastViewWidth;
				this.layout();
			}
			if (isHScrollVisible != scrollBar.hScroll.isVisible()) {
				this.correctSummaryPosition();
			}
			this.enableLastRowWithoutBorderMode(scrollBar.vScroll.isVisible());
		}
	},

	correctSummaryPosition: function() {
		var bottomPosition = 0;
		var scrollBar = this.scrollBar;
		if (scrollBar.hScroll.isVisible()) {
			bottomPosition = scrollBar.getHScrollHeight();
		}
		this.summary.dom.style.bottom = this.summary.addUnits(bottomPosition);
	},

	getScrollConfig: function() {
		var config = new Object();
		var treegrid = this.treegrid;
		var indentBottom = 0;
		if (treegrid.isSummaryVisible) {
			indentBottom = this.summary.getHeight() - 1;
		}
		config.indentBottom = (indentBottom > 0) ? indentBottom : 0;
		return config;
	},

	syncScroll: function(scrollLeft, scrollTop) {
		if (this.mainHd && (this.mainHd.dom.style.left != scrollLeft)) {
			this.mainHd.dom.style.left = scrollLeft;
		}
		if (this.summary && this.summary.dom.left != scrollLeft) {
			this.summary.dom.style.left = scrollLeft;
		}
	},

	scrollTo: function(el) {
		var scrollBar = this.scrollBar;
		if (scrollBar.vScroll.isVisible() || scrollBar.hScroll.isVisible()) {
			this.scroller.dom.firstChild.scrollToElement(el);
		}
	},

	scrollToTop: function() {
		var rows = this.mainBody.dom.childNodes;
		if (rows.length > 0) {
			var topRow = rows[0];
			this.scrollTo(topRow);
		}
	},

	enableLastRowWithoutBorderMode: function(enable) {
		var rows = this.getRows();
		var className = "border-bottom-transparent";
		if (rows.length > 1) {
			var lastRowIndex = rows.length - 1;
			var lastRow = Ext.get(rows[lastRowIndex]);
			if (lastRow) {
				if (enable) {
					var prevRow = Ext.get(rows[lastRowIndex - 1]);
					prevRow.removeClass(className);
					lastRow.addClass(className);
				} else {
					lastRow.removeClass(className);
				}
			}
		}
	},

	updateAllColumnWidths: function() {
		var tw = this.getTotalWidth();
		var colModel = this.treegrid.getColumnModel();
		var clen = colModel.getColumnCount();
		var ws = [];
		for (var i = 0; i < clen; i++) {
			ws[i] = this.getColumnWidth(i);
		}
		var column, position;
		var ns = this.getRows();
		var row;
		for (var i = 0, len = ns.length; i < len; i++) {
			row = ns[i];
			for (var j = 0; j < clen; j++) {
				if (colModel.isVisible(j)) {
					position = this.getColumnPosition(j);
					this.updateTreeColumn(row, position, ws[j], tw, '');
				}
			}
		}
		this.updateAllColumnHeaderWidth(ws, tw);
		this.updateEmptySpaceAllColumnWidth(ws, tw);
		this.onAllColumnWidthsUpdated(ws, tw);
	},

	updateAllColumnHeaderWidth: function(ws, totalWidth) {
		this.applyDomWidth(this.innerHd.firstChild.firstChild, totalWidth);
		var position;
		var colModel = this.treegrid.getColumnModel();
		var clen = colModel.getColumnCount();
		for (var i = 0; i < clen; i++) {
			if (colModel.isVisible(i)) {
				position = this.getColumnPosition(i);
				var hd = this.getHeaderCell(position);
				this.applyDomWidth(hd, ws[i]);
			}
		}
	},

	updateEmptySpaceAllColumnWidth: function(ws, totalWidth) {
		var emptySpaceNode = this.getEmptySpaceNode();
		if (emptySpaceNode) {
			var position;
			var colModel = this.treegrid.getColumnModel();
			var clen = colModel.getColumnCount();
			for (var i = 0; i < clen; i++) {
				if (colModel.isVisible(i)) {
					position = this.getColumnPosition(i);
					this.updateTreeColumn(emptySpaceNode, position, ws[i], totalWidth, '');
				}
			}
		}
	},

	updateTreeColumn: function(row, col, width, totalWidth, display) {
		this.applyDomWidth(row.firstChild, totalWidth);
		var column = row.firstChild.rows[0].childNodes[col];
		this.applyDomWidth(column, width);
		if (column != undefined) {
			column.style.display = display;
		}
	},

	getColumnPosition: function(col) {
		var columnModel = this.treegrid.getColumnModel();
		return columnModel.getColumnPosition(col);
	},

	updateColumnWidth: function(col, width) {
		var tw = this.getTotalWidth();
		var position = this.getColumnPosition(col);
		var ns = this.getRows();
		for (var i = 0, count = ns.length; i < count; i++) {
			this.updateTreeColumn(ns[i], position, width, tw, '');
		}
		this.updateColumnHeaderWidth(position, width, tw);
		this.updateEmptySpaceColumnWidth(position, width, tw);
		this.onColumnWidthUpdated(col, width, tw);
	},

	updateColumnHeaderWidth: function(position, width, totalWidth) {
		this.applyDomWidth(this.innerHd.firstChild.firstChild, totalWidth);
		var hd = this.getHeaderCell(position);
		this.applyDomWidth(hd, width);
	},

	updateEmptySpaceColumnWidth: function(position, width, totalWidth) {
		var emptySpaceNode = this.getEmptySpaceNode();
		if (!emptySpaceNode) {
			return;
		}
		this.updateTreeColumn(emptySpaceNode, position, width, totalWidth, '');
	},

	onColumnHidden: function(position) {
		if (position == 0) {
			this.refreshPage(true);
		} else {
			this.deleteColumn(position);
			if (!this.treegrid.isColumnAutowidth) {
				this.updateScroll();
			}
		}
	},

	applyDomWidth: function(dom, width) {
		if (typeof width == "number") {
			width += "px";
		}
		if (dom != undefined) {
			dom.style.width = width;
		}
	},

	refreshPage: function(doRefreshSummaries) {
		this.treegrid.onRefreshPage(doRefreshSummaries);
	},

	deleteColumn: function(position) {
		this.updateHeaders();
		var totalWidth = this.getTotalWidth();
		var ns = this.getRows();
		var row, innerRow, columnNode;
		for (var i = 0, len = ns.length; i < len; i++) {
			this.removeRowColumn(ns[i], position, totalWidth);
		}
		var emptySpace = this.getEmptySpaceNode();
		this.removeRowColumn(emptySpace, position, totalWidth);
		this.onColumnDeleted(position);
		delete this.lastViewWidth;
		this.layout();
	},

	removeRowColumn: function(rowNode, position, totalWidth) {
		var row, innerRow, columnNode;
		row = rowNode.firstChild;
		this.applyDomWidth(row, totalWidth);
		innerRow = row.rows[0];
		columnNode = innerRow.childNodes[position];
		innerRow.removeChild(columnNode);
	},

	doRender: function(cs, rs, ds, startRow, colCount, stripe) {

	},

	doSummary: function(buf, rs, cs, ds, colCount) {
		return this.templates.summary;
	},

	getChildsContainer: function(row) {
		var node = row.child("UL");
		if (node) {
			return node.dom;
		}
		return null;
	},

	processRows: function() {
		delete this.rows;
		var rows = this.mainBody.dom.childNodes;
		this.isAlt = false;
		var row;
		for (var i = 0, len = rows.length; i < len; i++) {
			row = Ext.get(rows[i]);
			if (!this.isEmptySpaceNode(row.dom)) {
				this.processRow(row);
			}
		}
	},

	processRow: function(row) {
		if (this.treegrid.stripeRows) {
			var stripedRowCss = this.treegrid.stripedRowCss;
			this.isAlt = !this.isAlt;
			var hasAlt = row.hasClass(stripedRowCss);
			if (this.isAlt != hasAlt) {
				if (this.isAlt) {
					row.addClass(stripedRowCss);
				} else {
					row.removeClass(stripedRowCss);
				}
			}
		}
		var childsContainer = this.getChildsContainer(row);
		if ((childsContainer) && (childsContainer.style.display != 'none')) {
			var childs = childsContainer.childNodes;
			for (var i = 0, count = childs.length; i < count; i++) {
				this.processRow(Ext.get(childs[i]));
			}
		}
	},

	afterRender: function() {
		if (this.deferEmptyText !== true) {
			this.applyEmptyText();
		}
	},

	renderUI: function() {
		var treegrid = this.treegrid;
		this.initElements();
		var headerNode = Ext.fly(this.innerHd);
		headerNode.on("click", this.handleHdDown, this);
		headerNode.on("contextmenu", this.handleColumnHeaderContextMenu, this);
		this.mainHd.on("mouseover", this.handleHdOver, this);
		this.mainHd.on("mouseout", this.handleHdOut, this);
		this.mainHd.on("mousemove", this.handleHdMove, this);
		if (treegrid.enableColumnResize !== false) {
			this.splitone = new Ext.treegrid.GridView.SplitDragZone(treegrid, this.mainHd.dom);
		}
		if (treegrid.enableColumnMove) {
			this.columnDrag = new Ext.treegrid.GridView.ColumnDragZone(treegrid, this.innerHd);
			this.columnDrop = new Ext.treegrid.HeaderDropZone(treegrid, this.mainHd.dom);
		}
		if (treegrid.enableHdMenu !== false) {
			this.hmenu = new Ext.menu.Menu({ id: treegrid.id + "-hctx" });
			var treeGridStringList = Ext.StringList('WC.TreeGrid');
			this.hmenu.add(
				{ id: "Ascending", caption: treeGridStringList.getValue('ColumnsMenu.SortAscending'), cls: "xg-hmenu-sort-asc" },
				{ id: "Descending", caption: treeGridStringList.getValue('ColumnsMenu.SortDescending'), cls: "xg-hmenu-sort-desc" }
			);
			if (!treegrid.isVirtual()) {
				if (treegrid.enableColumnHide !== false) {
					this.hmenu.add('-',
						{ id: "setcolumns", caption: treeGridStringList.getValue('ColumnsMenu.SetColumns') },
						{ id: "removecolumn", caption: treeGridStringList.getValue('ColumnsMenu.HideColumn') }
					);
				}
			}
			var separatorSet = false;
			if (treegrid.showAutoWidthMenu) {
				this.hmenu.add('-', { id: "autowidth", caption: treeGridStringList.getValue('ColumnsMenu.Autowidth'), checked: treegrid.isColumnAutowidth });
				separatorSet = true;
			}
			if (treegrid.showMultiLineMenu) {
				this.hmenu.add(separatorSet ? null : '-', { id: "multiline", caption: treeGridStringList.getValue('ColumnsMenu.Multiline'), checked: treegrid.isMultilineMode });
				separatorSet = true;
			}
			if (!treegrid.isVirtual() && treegrid.showSummariesMenu) {
				this.hmenu.add(separatorSet ? null : '-', { id: "summary", caption: treeGridStringList.getValue('ColumnsMenu.Summaries'), checked: treegrid.isSummaryVisible });
			}
			this.hmenu.on("beforeshow", this.beforeHdMenuShow, this);
			this.hmenu.on("itemclick", this.handleHdMenuClick, this);
		}
	},

	layout: function() {
		if (!this.mainBody) {
			return;
		}
		var treegrid = this.treegrid;
		var c = treegrid.getGridEl();
		var csize = c.getSize(true);
		var vw = csize.width;
		var vh = csize.height;

		if (vw < 20 || csize.height < 20) {
			return;
		}
		if (treegrid.isColumnAutowidth) {
			if (this.lastViewWidth != vw) {
				this.fitColumns(false, false);
				this.lastViewWidth = vw;
			}
		} else {
			var cm = treegrid.getColumnModel();
			var availableWidth = this.getAvailableWidth();
			if (0 < availableWidth - cm.getTotalWidth()) {
				this.fitColumns(false, false);
			}
		}
		var emptySpaceNode = Ext.get(this.getEmptySpaceNode());
		if (emptySpaceNode) {
			emptySpaceNode.repaint();
		}
		this.onLayout(vw, vh);
		treegrid.dataSource.setColumnsProfileData();
	},

	onLayout: function(vw, vh) {
	},

	onColumnWidthUpdated: function(col, w, tw) {
		this.updateScroll();
	},

	onAllColumnWidthsUpdated: function(ws, tw) {
		this.updateScroll();
	},

	onColumnHiddenUpdated: function(col, w, tw, display) {
	},

	onColumnDeleted: function(position) {
	},

	onColumnMoved: function(oldPosition, newPosition) {

	},

	updateColumnText: function(col, text) {
	},

	afterMove: function(colIndex) {
	},

	init: function(treegrid) {
		this.treegrid = treegrid;
		this.initTemplates();
		this.initColumnModelEvents();
		this.initUI(treegrid);
	},

	getColumnName: function(index) {
		var colModel = this.treegrid.getColumnModel();
		return colModel.getColumnName(index);
	},

	renderHeaders: function() {
		var cm = this.treegrid.getColumnModel();
		var ts = this.templates;
		var ct = ts.hcell;
		var cb = [], p = {};
		var sortingColumns = this.treegrid.getSortingColumns();
		var sortCount = sortingColumns.length;
		if (cm) {
			for (var i = 0, len = cm.getColumnCount(); i < len; i++) {
				if (cm.isVisible(i)) {
					var column = cm.getColumn(i);
					p.name = column.name;
					p.value = Ext.util.Format.htmlEncode(column.caption) || "";
					p.style = this.getColumnStyle(i, true);
					var orderPosition = sortingColumns.indexOf(column);
					if (orderPosition != -1) {
						p.sortIndex = sortCount > 1 ? orderPosition + 1 : "";
						p.orderDirectionClass = this.sortClasses[column.orderDirection == "Ascending" ? 0 : 1];
					} else {
						p.sortIndex = "";
						p.orderDirectionClass = "";
					}
					p.lastColumn = cm.isLastVisibleColumn(i) ? "last-column" : "";
					if (cm.config[i].align == 'right') {
						p.istyle = 'padding-right:16px';
					} else {
						delete p.istyle;
					}
					cb[cb.length] = ct.apply(p);
				}
			}
		}
		return ts.header.apply({ cells: cb.join(""), tstyle: 'width:' + this.getTotalWidth() + ';' });
	},

	getColumnTooltip: function(i) {
		var colModel = this.treegrid.getColumnModel();
		var tt = colModel.getColumnTooltip(i);
		if (tt) {
			if (Ext.QuickTips.isEnabled()) {
				return 'ext:qtip="' + tt + '"';
			} else {
				return 'title="' + tt + '"';
			}
		}
		return "";
	},

	beforeUpdate: function() {
		this.treegrid.stopEditing(true);
	},

	updateHeaders: function() {
		this.innerHd.firstChild.innerHTML = this.renderHeaders();
		this.updateScrollerElementHeight();
	},

	deleteHeaders: function() {
		this.innerHd.firstChild.innerHTML = "";
	},

	getColumnStyle: function(col, isHeader) {
		var style = 'width:' + this.getColumnWidth(col) + ';';
		var colModel = this.treegrid.getColumnModel();
		if (!colModel.isVisible(col)) {
			style += 'display:none;';
		}
		return style;
	},

	getColumnWidth: function(col) {
		var colModel = this.treegrid.getColumnModel();
		var w = colModel.getColumnWidth(col);
		if (typeof w == 'number') {
			return w + 'px';
		}
		return w;
	},

	getTotalWidth: function() {
		var colModel = this.treegrid.getColumnModel();
		if (!colModel) {
			return 0;
		}
		return colModel.getTotalWidth() + 'px';
	},

	getAvailableWidth: function() {
		var width = this.treegrid.getGridEl().getWidth(true);
		if (!Ext.isAppleSafari) {
			width -= this.treegrid.getColumnModel().getColumnCount(true) * this.columnPaddingSize;
		}
		this.scrollOffset = 0;
		var scrollBar = this.scrollBar;
		if (scrollBar && scrollBar.vScroll.isVisible()) {
			width -= (this.scrollOffset = scrollBar.getVScrollWidth());
		}
		return width;
	},

	fitColumns: function(preventRefresh, onlyExpand, omitColumn) {
		var treegrid = this.treegrid;
		var columnModel = treegrid.getColumnModel();
		var availableWidth = this.getAvailableWidth();
		if (availableWidth < 20) {
			return false;
		}
		var extra = availableWidth - columnModel.getTotalWidth(false);
		if (extra === 0) {
			return false;
		}
		var visibleColumnsCount = columnModel.getColumnCount(true);
		var ac = visibleColumnsCount - (typeof omitColumn == 'number' ? 1 : 0);
		if (ac === 0) {
			ac = 1;
			omitColumn = undefined;
		}
		var colCount = 0;
		if (columnModel) {
			colCount = columnModel.getColumnCount();
		}
		var cols = [];
		var extraCol = 0;
		var width = 0;
		var w;
		var i;
		var firstResizeColumnNumber = (typeof omitColumn == 'number' ? omitColumn + 1 : 0);
		for (i = firstResizeColumnNumber; i < colCount; i++) {
			if (columnModel.isVisible(i) && !columnModel.isFixed(i) &&
					(columnModel.isAutoFit(i) != false) && i !== omitColumn) {
				w = columnModel.getColumnWidth(i);
				cols.push(i);
				extraCol = i;
				cols.push(w);
				width += w;
			}
		}
		var ratio = extra / width;
		var columnWidth;
		while (cols.length) {
			w = cols.pop();
			i = cols.pop();
			columnWidth = Math.max(treegrid.minColumnWidth, Math.floor(w + w * ratio));
			columnModel.setColumnWidth(i, columnWidth, true);
		}
		var rightGap = (columnModel.getTotalWidth(false) - availableWidth);
		if (rightGap != 0) {
			var adjustCol = ac != visibleColumnsCount ? omitColumn : extraCol;
			if (adjustCol != undefined) {
				columnWidth = Math.max(1, columnModel.getColumnWidth(adjustCol) - rightGap);
				columnModel.setColumnWidth(adjustCol, columnWidth, true);
			}
		}
		if (preventRefresh !== true) {
			this.updateAllColumnWidths();
		}
		return true;
	},

	getColumnData: function() {
		var cs = [], cm = this.treegrid.getColumnModel(), colCount = cm.getColumnCount();
		for (var i = 0; i < colCount; i++) {
			var name = cm.getColumnName(i);
			cs[i] = {
				name: (typeof name == 'undefined' ? this.ds.fields.get(i).name : name),
				renderer: cm.getRenderer(i),
				id: cm.getColumnName(i),
				style: this.getColumnStyle(i)
			};
		}
		return cs;
	},

	renderRows: function(startRow, endRow) {
		var treegrid = this.treegrid, cm = treegrid.getColumnModel(), ds = treegrid.store, stripe = treegrid.stripeRows;
		var colCount = 0;
		if (cm) {
			colCount = cm.getColumnCount();
		}
		var dsCount = 0;
		if (ds) {
			dsCount = ds.getCount();
		}
		if (dsCount < 1) {
			return "";
		}
		var cs = this.getColumnData();
		startRow = startRow || 0;
		endRow = typeof endRow == "undefined" ? ds.getCount() - 1 : endRow;
		var rs = ds.getRange(startRow, endRow);
		return this.doRender(cs, rs, ds, startRow, colCount, stripe);
	},

	renderSummary: function() {
		this.clearSummary();
		summaryPlugin = this.treegrid.getSummaryPlugin();
		summaryPlugin.initEvents();
		summaryPlugin.requestSummaries();
	},

	clearSummary: function() {
		var markup = this.doSummary();
		var summaryHTML = this.templates.body.apply({ rows: markup });
		this.summary.update(summaryHTML);
	},

	refresh: function(headersToo) {
		this.fireEvent("beforerefresh", this);
		this.treegrid.stopEditing(true);
		if (this.treegrid.isSummaryVisible) {
			this.renderSummary();
		}
		if (headersToo === true) {
			this.updateHeaders();
			this.syncSortUI();
		}
		this.layout();
		this.applyEmptyText();
		this.fireEvent("refresh", this);
	},

	getCellValue: function(cell) {
		var cell = Ext.get(cell);
		var innerCell = cell.child('.x-treegrid-cell-inner');
		var valueNode = innerCell.child('.value');
		if (valueNode) {
			return valueNode.dom.innerHTML;
		} else {
			return "";
		}
	},

	setCellValue: function(cell, value) {
		var cell = Ext.get(cell);
		var innerCell = cell.child('.x-treegrid-cell-inner');
		var valueNode = innerCell.child('.value');
		if (valueNode) {
			valueNode.dom.innerHTML = value;
		}
	},

	setBoolCellValue: function(cell, value) {
		var cell = Ext.get(cell);
		var innerCell = cell.child('.x-treegrid-cell-inner');
		var valueNode = innerCell.child('.value');
		if (valueNode) {
			valueNode.removeClass("true");
			valueNode.removeClass("false");
			valueNode.addClass(value.toLowerCase());
		}
	},

	moveRowColumns: function(row, firstIndex, secondIndex) {
		var lastColumnClassName = "last-column";
		row = row.firstChild.firstChild;
		var firstColumn = row.childNodes[firstIndex];
		if (firstColumn == row.lastChild) {
			Ext.get(firstColumn).removeClass(lastColumnClassName);
			Ext.get(firstColumn.previousSibling).addClass(lastColumnClassName);
		}
		var secondColumn = row.childNodes[secondIndex];
		if (secondColumn == row.lastChild) {
			Ext.get(secondColumn).removeClass(lastColumnClassName);
		}
		var el = secondColumn;
		if (firstIndex < secondIndex) {
			el = secondColumn.nextSibling;
		}
		secondColumn.parentNode.insertBefore(firstColumn, el);
		if (firstColumn == row.lastChild) {
			Ext.get(row.lastChild).addClass(lastColumnClassName);
		}
	},

	moveHeaderColumns: function(firstIndex, secondIndex) {
		var headerTableNode = this.mainHd.dom.firstChild.firstChild.firstChild;
		if (headerTableNode) {
			this.moveRowColumns(headerTableNode, firstIndex, secondIndex);
		}
	},

	moveEmptySpaceColumns: function(firstIndex, secondIndex) {
		var emptySpaceNode = this.getEmptySpaceNode();
		var emptySpaceTableNode = emptySpaceNode.firstChild;
		if (emptySpaceTableNode) {
			this.moveRowColumns(emptySpaceTableNode, firstIndex, secondIndex);
		}
	},

	moveColumnsData: function(oldPosition, newPosition) {
		this.moveHeaderColumns(oldPosition, newPosition);
		var ns = this.getRows();
		var rowTableNode;
		for (var i = 0, count = ns.length; i < count; i++) {
			rowTableNode = Ext.get(ns[i]).child('table.x-treegrid-row-table');
			this.moveRowColumns(rowTableNode.dom, oldPosition, newPosition);
		}
		this.moveEmptySpaceColumns(oldPosition, newPosition);
	},

	applyEmptyText: function() {
		if (this.emptyText && !this.hasRows()) {
			this.mainBody.update('<div class="x-treegrid-empty">' + this.emptyText + '</div>');
		}
	},

	destroy: function() {
		if (this.colMenu) {
			this.colMenu.removeAll();
			Ext.menu.MenuMgr.unregister(this.colMenu);
			this.colMenu.getEl().remove();
			delete this.colMenu;
		}
		if (this.hmenu) {
			this.hmenu.removeAll();
			Ext.menu.MenuMgr.unregister(this.hmenu);
			this.hmenu.getEl().remove();
			delete this.hmenu;
		}
		if (this.tbmenu) {
			this.tbmenu.removeAll();
			Ext.menu.MenuMgr.unregister(this.tbmenu);
			this.tbmenu.getEl().remove();
			delete this.tbmenu;
		}
		if (this.treegrid.enableColumnMove) {
			var dds = Ext.dd.DDM.ids['gridHeader' + this.treegrid.getGridEl().id];
			if (dds) {
				for (var dd in dds) {
					if (!dds[dd].config.isTarget && dds[dd].dragElId) {
						var elid = dds[dd].dragElId;
						dds[dd].unreg();
						Ext.get(elid).remove();
					} else if (dds[dd].config.isTarget) {
						dds[dd].proxyTop.remove();
						dds[dd].proxyBottom.remove();
						dds[dd].unreg();
					}
					if (Ext.dd.DDM.locationCache[dd]) {
						delete Ext.dd.DDM.locationCache[dd];
					}
				}
				delete Ext.dd.DDM.ids['gridHeader' + this.treegrid.getGridEl().id];
			}
		}

		Ext.destroy(this.resizeMarker, this.resizeProxy);

		if (this.dragZone) {
			this.dragZone.unreg();
		}
		Ext.EventManager.removeResizeListener(this.onWindowResize, this);
	},

	render: function() {
		if (this.autoFill) {
			this.fitColumns(true, true);
		} else if (this.treegrid.isColumnAutowidth) {
			this.fitColumns(true, false);
		}
		this.renderUI();
	},

	initColumnModelEvents: function() {
		var cm = this.treegrid.getColumnModel();
		if (cm) {
			delete this.lastViewWidth;
			cm.on("configchange", this.onColConfigChange, this);
			cm.on("widthchange", this.onColWidthChange, this);
			cm.on("headerchange", this.onHeaderChange, this);
			cm.on("columnmoved", this.moveColumn, this);
			cm.on("columnlockchange", this.onColumnLock, this);
		}
	},

	onDataChanged: function() {
		this.refresh();
		this.treegrid.syncSortingUI();
	},

	onClear: function() {
		this.refresh();
	},

	onRemove: function(ds, row, index, isUpdate) {
		if (isUpdate !== true) {
			this.fireEvent("beforerowremoved", this, index, row);
		}
		this.removeRow(index);
		if (isUpdate !== true) {
			this.processRows(index);
			this.applyEmptyText();
			this.fireEvent("rowremoved", this, index, row);
		}
	},

	onColWidthChange: function(cm, col, width) {
		delete cm.totalWidth;
		this.updateColumnWidth(col, width);
	},

	onHeaderChange: function(cm, col, text) {
		this.updateHeaders();
	},

	moveColumn: function(columnUId, position) {
		var treegrid = this.treegrid;
		treegrid.showLoadMask(treegrid.root);
		var columnModel = treegrid.columnModel;
		var columns = columnModel.config;
		var column = columnModel.getColumnByUId(columnUId);
		var index = columns.indexOf(column);
		var oldPosition = columnModel.getColumnPosition(index);
		var newPosition = columnModel.getColumnPosition(position);
		var refreshData = ((oldPosition === 0) || (newPosition === 0));
		if (refreshData) {
			treegrid.clear(true);
		}
		treegrid.dataSource.moveStructureColumn(columnUId, position, refreshData);
	},

	onColumnMove: function(cm, oldPosition, newPosition) {
		this.indexMap = null;
		delete cm.totalWidth;
		this.moveColumnsData(oldPosition, newPosition);
		this.afterMove(newPosition);
		this.onColumnMoved(oldPosition, newPosition);
	},

	onColConfigChange: function() {
		delete this.lastViewWidth;
		this.indexMap = null;
		this.refresh(true);
	},

	initUI: function(treegrid) {
		treegrid.on("headerclick", this.onHeaderClick, this);
		if (treegrid.trackMouseOver) {
			treegrid.on("mouseover", this.onRowOver, this);
			treegrid.on("mouseout", this.onRowOut, this);
		}
	},

	initEvents: function() {

	},

	onHeaderClick: function(g, index) {
		var colModel = this.treegrid.getColumnModel();
		if (this.headersDisabled || !colModel.isSortable(index)) {
			return;
		}
		g.stopEditing(true);
	},

	onRowOver: function(e, t) {
		var row;
		if ((row = this.findRowIndex(t)) !== false) {
			this.addRowClass(row, "x-treegrid-row-over");
		}
	},

	onRowOut: function(e, t) {
		var row;
		if ((row = this.findRowIndex(t)) !== false && row !== this.findRowIndex(e.getRelatedTarget())) {
			this.removeRowClass(row, "x-treegrid-row-over");
		}
	},

	onDestroy: function() {
		this.colMenu.destroy();
		this.hMenu.destroy();
		this.columnSortingHash = null;
		Ext.treegrid.GridView.superclass.onDestroy.call(this);
	},

	handleWheel: function(e) {
		e.stopPropagation();
	},

	onColumnSplitterMoved: function(i, w) {
		this.treegrid.stopEditing(true);
		this.userResized = true;
		var cm = this.treegrid.getColumnModel();
		cm.setColumnWidth(i, w, true);
		delete cm.totalWidth;
		if (this.treegrid.isColumnAutowidth) {
			this.fitColumns(false, false, i);
		} else {
			this.updateColumnWidth(i, w);
			var availableWidth = this.getAvailableWidth();
			if (0 < availableWidth - cm.getTotalWidth()) {
				this.fitColumns(false, false, i);
			}
		}
		this.treegrid.fireEvent("columnresize", i, w);
		this.treegrid.dataSource.setColumnsProfileData();
	},

	handleHdMenuClick: function(item) {
		var index = this.hdCtxIndex;
		var result = true;
		switch (item.id) {
			case "Ascending":
				this.handleSortingMenuClick(index, item);
				break;
			case "Descending":
				this.handleSortingMenuClick(index, item);
				break;
			case "summary":
				this.handleSummaryMenuClick(item);
				break;
			case "autowidth":
				this.handleAutowidthMenuClick(item);
				break;
			case "multiline":
				this.handleMultilineMenuClick(item);
				break;
			case "setcolumns":
				this.handleSetColumnsMenuClick();
				break;
			case "removecolumn":
				this.handleRemoveColumnMenuClick(index, item);
				break;
		}
		return result;
	},

	handleSortingMenuClick: function(columnIndex, menuItem) {
		var direction = menuItem.id;
		var columnModel = this.treegrid.getColumnModel();
		if (columnModel.isSortable(columnIndex)) {
			var column = columnModel.getColumn(columnIndex);
			this.treegrid.addSorting(column, direction, false);
		}
	},

	handleSummaryMenuClick: function(menuItem) {
		this.showSummary(!menuItem.checked);
	},

	getDataHeight: function() {
		var rows = this.getRows();
		var height = 0;
		var row;
		for (var i = 0, count = rows.length; i < count; i++) {
			row = rows[i];
			if (!this.isEmptySpaceNode(row)) {
				height += row.offsetHeight;
			}
		}
		return height;
	},

	setElPosition: function() {
		var topPadding = 0;
		var bottomPadding = 0;
		var treegrid = this.treegrid;
		if (treegrid.bbar) {
			var footerHeight = treegrid.bbar.getHeight();
			bottomPadding += footerHeight;
		}
		var elStyle = this.el.dom.style;
		elStyle.top = this.el.addUnits(topPadding);
		elStyle.bottom = this.el.addUnits(bottomPadding);
	},

	updateScrollerElementHeight: function() {
		var scroller = this.scroller;
		var topPadding = 0;
		var bottomPadding = 0;
		var treegrid = this.treegrid;
		if (this.mainHd && !treegrid.hideHeaders) {
			var headerHeight = treegrid.isVisible(true) ? this.mainHd.getHeight() : this.getRawHeaderHeight();
			topPadding += headerHeight + (headerHeight > 0 && Ext.isIE ? 1 : 0);
		}
		if (treegrid.topToolbar) {
			var tbarHeight = treegrid.topToolbar.getHeight();
			bottomPadding += tbarHeight;
		}
		scroller.dom.style.top = scroller.addUnits(topPadding);
		scroller.dom.style.bottom = scroller.addUnits(bottomPadding);
	},

	getRawHeaderHeight: function() {
		var treegrid = this.treegrid;
		var rawId = treegrid.id + "_RawHeight";
		var el = Ext[rawId];
		if (!el) {
			var el = Ext.get(document.createElement('div'));
			el.dom.style.marginTop = '-10000px';
			document.body.appendChild(el.dom);
			Ext[rawId] = el;
		}
		var header = new Ext.Template(
			'<div class="x-treegrid-header"><div class="x-treegrid-header-inner"><div class="x-treegrid-header-offset">{header}</div></div><div class="x-clear"></div></div>'
		);
		var ts = this.templates;
		var html = ts.hcell.apply({value: "0"});
		html = ts.header.apply({ cells: html});
		html = header.apply({header: html});
		el.dom.innerHTML = html;
		var headerEl = el.child('div.x-treegrid-header');
		var offsetHeight = headerEl.dom.offsetHeight;
		el.dom.innerHTML = '';
		return offsetHeight;
	},

	handleAutowidthMenuClick: function(menuItem) {
		this.enableColumnAutowidth(!menuItem.checked);
	},

	handleMultilineMenuClick: function(menuItem) {
		this.enableMultiline(!menuItem.checked);
	},

	beforeHdMenuShow: function() {
		var menu = this.hmenu;
		var treegrid = this.treegrid;
		treegrid.setMenuItemChekedValue(menu, "summary", treegrid.isSummaryVisible);
		treegrid.setMenuItemChekedValue(menu, "multiline", treegrid.isMultilineMode);
		treegrid.setMenuItemChekedValue(menu, "autowidth", treegrid.isColumnAutowidth);
	},

	handleSetColumnsMenuClick: function() {
		var treegrid = this.treegrid;
		if (treegrid.fireEvent("beforesetcolumns") !== false) {
			treegrid.fireEvent("setcolumns");
		}
	},

	handleRemoveColumnMenuClick: function(columnIndex, menuItem) {
		this.treegrid.removeColumn(columnIndex);
	},

	getColumnHeaderMenu: function(t) {
		var hd = this.findHeaderCell(t);
		var index = this.getCellIndex(hd);
		Ext.fly(hd).addClass('x-treegrid-hd-menu-open');
		this.hdCtxIndex = index;
		var hdMenu = this.hmenu;
		var menuItems = hdMenu.items;
		var cm = this.treegrid.getColumnModel(); ;
		menuItems.get("Ascending").setDisabled(!cm.isSortable(index));
		menuItems.get("Descending").setDisabled(!cm.isSortable(index));
		hdMenu.on("hide", function() {
			Ext.fly(hd).removeClass('x-treegrid-hd-menu-open');
		}, this, { single: true });
		return hdMenu;
	},

	handleDblClick: function(e, t) {
		this.fireEvent("dblclick", e);
	},

	handleHdDown: function(e, t) {
		if (Ext.fly(t).hasClass('x-treegrid-hd-btn')) {
			e.stopEvent();
			var hdMenu = this.getColumnHeaderMenu(t);
			hdMenu.show(t, "tl-bl?");
		} else {
			this.treegrid.focus();
			var hd = this.findHeaderCell(t);
			var index = this.getCellIndex(hd);
			if (index != null) {
				var columnModel = this.treegrid.getColumnModel();
				if (columnModel.isSortable(index)) {
					var column = columnModel.getColumn(index);
					var direction = (column.orderDirection == "Ascending") ? "Descending" : "Ascending";
					var clickCount = this.columnSortingHash[column.metaPath];
					if (!clickCount) {
						this.columnSortingHash[column.metaPath] = 1;
					} else {
						this.columnSortingHash[column.metaPath] = clickCount + 1;
					}
					this.treegrid.addSorting(column, direction, e.ctrlKey);
				}
			}
		}
	},

	handleColumnHeaderContextMenu: function(e, t) {
		e.stopEvent();
		var hdMenu = this.getColumnHeaderMenu(t);
		hdMenu.showAt(e.xy);
	},

	handleHdOver: function(e, t) {
		var hd = this.findHeaderCell(t);
		if (hd && !this.headersDisabled) {
			this.activeHd = hd;
			this.activeHdIndex = this.getCellIndex(hd);
			var fly = this.fly(hd);
			this.activeHdRegion = fly.getRegion();
			var colModel = this.treegrid.getColumnModel();
			if (!colModel.isMenuDisabled(this.activeHdIndex)) {
				fly.addClass("x-treegrid-hd-over");
			}
		}
	},

	handleHdMove: function(e, t) {
		if (this.activeHd && !this.headersDisabled) {
			var hw = this.splitHandleWidth || 5;
			var r = this.activeHdRegion;
			var x = e.getPageX();
			var ss = this.activeHd.style;
			var colModel = this.treegrid.getColumnModel();
			if (x - r.left <= hw && colModel.isResizable(this.activeHdIndex - 1)) {
				ss.cursor = Ext.isAir ? 'move' : Ext.isSafari ? 'e-resize' : 'col-resize';
			} else if (r.right - x <= (!this.activeHdBtn ? hw : 2) && colModel.isResizable(this.activeHdIndex)) {
				ss.cursor = Ext.isAir ? 'move' : Ext.isSafari ? 'w-resize' : 'col-resize';
			} else {
				ss.cursor = '';
			}
		}
	},

	handleHdOut: function(e, t) {
		var hd = this.findHeaderCell(t);
		if (hd && (!Ext.isIE || !e.within(hd, true))) {
			this.activeHd = null;
			this.fly(hd).removeClass("x-treegrid-hd-over");
			hd.style.cursor = '';
		}
	},

	hasRows: function() {
		return !Ext.isEmpty(this.getRows());
	},

	enableMultiline: function(enabled) {
		var treegrid = this.treegrid;
		if (treegrid.isMultilineMode != enabled) {
			var scroller = this.scroller;
			var multilineClass = this.multilineClass;
			if (enabled) {
				scroller.addClass(multilineClass);
			} else {
				scroller.removeClass(multilineClass);
			}
			var rows = this.getRows();
			var row;
			for (var i = 0, count = rows.length; i < count; i++) {
				row = Ext.get(rows[i]);
				row.repaint();
			}
			treegrid.isMultilineMode = enabled;
			treegrid.setProfileData('isMultilineMode', enabled);
		}
		this.updateScroll();
	},

	enableColumnAutowidth: function(enabled) {
		var treegrid = this.treegrid;
		if (treegrid.isColumnAutowidth != enabled) {
			treegrid.isColumnAutowidth = enabled;
			treegrid.setProfileData('isColumnAutowidth', enabled);
			if (enabled) {
				delete this.lastViewWidth;
				this.layout();
			}
		}
	},

	showSummary: function(visible) {
		var treegrid = this.treegrid;
		var summary = treegrid.getSummaryPlugin();
		if (treegrid.isSummaryVisible != visible) {
			summary.toggleSummaries(visible);
			var pagingToolbar = treegrid.getPagingToolbar();
			if (pagingToolbar) {
				var summaryButton = pagingToolbar.items.get("summary");
				if (summaryButton) {
					summaryButton.toggle(visible);
				}
				this.updateScrollerElementHeight();
			}
		}
		this.updateScroll();
	}
});

Ext.treegrid.GridView.SplitDragZone = function(treegrid, hd) {
	this.treegrid = treegrid;
	this.view = treegrid.getView();
	this.marker = this.view.resizeMarker;
	this.proxy = this.view.resizeProxy;
	Ext.treegrid.GridView.SplitDragZone.superclass.constructor.call(this, hd,
				"gridSplitters" + this.treegrid.getGridEl().id, {
					dragElId: Ext.id(this.proxy.dom), resizeFrame: false
				});
	this.scroll = false;
	this.hw = this.view.splitHandleWidth || 5;
};

Ext.extend(Ext.treegrid.GridView.SplitDragZone, Ext.dd.DDProxy, {

	b4StartDrag: function(x, y) {
		this.view.headersDisabled = true;
		var h = this.view.mainWrap.getHeight();
		this.marker.setHeight(h);
		this.marker.show();
		var position = this.view.getColumnPosition(this.cellIndex);
		this.marker.alignTo(this.view.getHeaderCell(position), 'tl-tl', [-2, 0]);
		this.proxy.setHeight(h);
		var colModel = this.treegrid.getColumnModel();
		var w = colModel.getColumnWidth(this.cellIndex);
		var minw = Math.max(w - this.treegrid.minColumnWidth, 0);
		this.resetConstraints();
		this.setXConstraint(minw, 1000);
		this.setYConstraint(0, 0);
		this.minX = x - minw;
		this.maxX = x + 1000;
		this.startPos = x;
		Ext.dd.DDProxy.prototype.b4StartDrag.call(this, x, y);
	},

	handleMouseDown: function(e) {
		var t = this.view.findHeaderCell(e.getTarget());
		if (t) {
			var xy = this.view.fly(t).getXY(), x = xy[0], y = xy[1];
			var exy = e.getXY(), ex = exy[0], ey = exy[1];
			var w = t.offsetWidth, adjust = false;
			if ((ex - x) <= this.hw) {
				adjust = -1;
			} else if ((x + w) - ex <= this.hw) {
				adjust = 0;
			}
			if (adjust !== false) {
				colModel = this.treegrid.getColumnModel();
				var ci = this.view.getCellIndex(t);
				if (adjust == -1) {
					if (ci + adjust < 0) {
						return;
					}
					while (!colModel.isVisible(ci + adjust)) {
						--adjust;
						if (ci + adjust < 0) {
							return;
						}
					}
				}
				this.cellIndex = ci + adjust;
				this.split = t.dom;
				if (colModel.isResizable(this.cellIndex) && !colModel.isFixed(this.cellIndex)) {
					Ext.treegrid.GridView.SplitDragZone.superclass.handleMouseDown.apply(this, arguments);
				}
			} else if (this.view.columnDrag) {
				this.view.columnDrag.callHandleMouseDown(e);
			}
		}
	},
	
	endDrag: function(e) {
		this.marker.hide();
		var v = this.view;
		var endX = Math.max(this.minX, e.getPageX());
		var diff = endX - this.startPos;
		var colModel = this.treegrid.getColumnModel();
		var cellIndex = this.cellIndex;
		if (!(this.treegrid.isColumnAutowidth && colModel.isLastVisibleColumn(cellIndex))) {
			v.onColumnSplitterMoved(cellIndex, colModel.getColumnWidth(cellIndex) + diff);
		}
		setTimeout(function() {
			v.headersDisabled = false;
		}, 50);
	},

	autoOffset: function() {
		this.setDelta(0, 0);
	}
});

Ext.treegrid.HeaderDragZone = function(treegrid, hd, hd2) {
	this.treegrid = treegrid;
	this.view = treegrid.getView();
	this.ddGroup = "gridHeader" + this.treegrid.getGridEl().id;
	Ext.treegrid.HeaderDragZone.superclass.constructor.call(this, hd);
	if (hd2) {
		this.setHandleElId(Ext.id(hd));
		this.setOuterHandleElId(Ext.id(hd2));
	}
	this.scroll = false;
};

Ext.extend(Ext.treegrid.HeaderDragZone, Ext.dd.DragZone, {
	maxDragWidth: 220,
	minDragWidth: 100,
	
	getDragData: function(e) {
		var t = Ext.lib.Event.getTarget(e);
		var h = this.view.findHeaderCell(t);
		if (h) {
			return { ddel: h.firstChild, header:h };
		}
		return false;
	},

	onInitDrag: function(e) {
		this.view.headersDisabled = true;
		var clone = this.dragData.ddel.cloneNode(true);
		clone.id = Ext.id();
		var width = this.dragData.header.offsetWidth;
		width = Math.max(width, this.minDragWidth);
		width = Math.min(width, this.maxDragWidth);
		clone.style.width = width + "px";
		this.proxy.update(clone);
		return true;
	},

	afterValidDrop: function() {
		var v = this.view;
		setTimeout(function() {
			v.headersDisabled = false;
		}, 50);
	},

	afterInvalidDrop: function() {
		var v = this.view;
		setTimeout(function() {
			v.headersDisabled = false;
		}, 50);
	}
});

Ext.treegrid.HeaderDropZone = function(treegrid, hd, hd2) {
	this.treegrid = treegrid;
	this.view = treegrid.getView();
	this.proxyTop = Ext.DomHelper.append(document.body, {
		cls: "col-move-top", html: "&#160;"
	}, true);
	this.proxyBottom = Ext.DomHelper.append(document.body, {
		cls: "col-move-bottom", html: "&#160;"
	}, true);
	this.proxyTop.hide = this.proxyBottom.hide = function() {
		this.setLeftTop(-100, -100);
		this.setStyle("visibility", "hidden");
	};
	this.ddGroup = "gridHeader" + this.treegrid.getGridEl().id;
	Ext.treegrid.HeaderDropZone.superclass.constructor.call(this, treegrid.getGridEl().dom);
};

Ext.extend(Ext.treegrid.HeaderDropZone, Ext.dd.DropZone, {
	proxyOffsets: [-4, -9],
	fly: Ext.Element.fly,

	getTargetFromEvent: function(e) {
		var t = Ext.lib.Event.getTarget(e);
		var cindex = this.view.findCellIndex(t);
		if (cindex !== false) {
			var position = this.view.getColumnPosition(cindex);
			return this.view.getHeaderCell(position);
		}
	},

	nextVisible: function(h) {
		var v = this.view, cm = this.treegrid.getColumnModel();
		h = h.nextSibling;
		while (h) {
			if (cm.isVisible(v.getCellIndex(h))) {
				return h;
			}
			h = h.nextSibling;
		}
		return null;
	},

	prevVisible: function(h) {
		var v = this.view, cm = this.treegrid.getColumnModel();
		h = h.prevSibling;
		while (h) {
			if (cm.isVisible(v.getCellIndex(h))) {
				return h;
			}
			h = h.prevSibling;
		}
		return null;
	},

	positionIndicator: function(h, n, e) {
		var x = Ext.lib.Event.getPageX(e);
		var r = Ext.lib.Dom.getRegion(n.firstChild);
		var px, pt, py = r.top + this.proxyOffsets[1];
		if ((r.right - x) <= (r.right - r.left) / 2) {
			px = r.right + this.view.columnPaddingSize;
			pt = "after";
		} else {
			px = r.left;
			pt = "before";
		}
		var oldIndex = this.view.getCellIndex(h);
		var newIndex = this.view.getCellIndex(n);
		var columnModel = this.treegrid.getColumnModel();
		if (columnModel.isFixed(newIndex)) {
			return false;
		}
		var locked = columnModel.isLocked(newIndex);
		if (pt == "after") {
			newIndex++;
		}
		if (oldIndex < newIndex) {
			newIndex--;
		}
		if (oldIndex == newIndex && (locked == columnModel.isLocked(oldIndex))) {
			return false;
		}
		px += this.proxyOffsets[0];
		this.proxyTop.setLeftTop(px, py);
		this.proxyTop.show();
		if (!this.bottomOffset) {
			this.bottomOffset = this.view.mainHd.getHeight();
		}
		this.proxyBottom.setLeftTop(px, py + this.proxyTop.dom.offsetHeight + this.bottomOffset);
		this.proxyBottom.show();
		return pt;
	},

	onNodeEnter: function(n, dd, e, data) {
		var result = false;
		if (data.header != n) {
			result = this.positionIndicator(data.header, n, e);
		}
		return result ? this.dropAllowed : this.dropNotAllowed;
	},

	onNodeOver: function(n, dd, e, data) {
		var result = false;
		if (data.header != n) {
			result = this.positionIndicator(data.header, n, e);
		}
		if (!result) {
			this.proxyTop.hide();
			this.proxyBottom.hide();
		}
		return result ? this.dropAllowed : this.dropNotAllowed;
	},

	onNodeOut: function(n, dd, e, data) {
		this.proxyTop.hide();
		this.proxyBottom.hide();
	},

	onNodeDrop: function(n, dd, e, data) {
		var h = data.header;
		if (h != n) {
			var cm = this.treegrid.getColumnModel();
			var x = Ext.lib.Event.getPageX(e);
			var r = Ext.lib.Dom.getRegion(n.firstChild);
			var pt = (r.right - x) <= ((r.right - r.left) / 2) ? "after" : "before";
			var oldIndex = this.view.getCellIndex(h);
			var newIndex = this.view.getCellIndex(n);
			var locked = cm.isLocked(newIndex);
			if (pt == "after") {
				newIndex++;
			}
			if (oldIndex < newIndex) {
				newIndex--;
			}
			if (oldIndex == newIndex && (locked == cm.isLocked(oldIndex))) {
				return false;
			}
			cm.setLocked(oldIndex, locked, true);
			cm.moveColumn(oldIndex, newIndex);
			this.treegrid.fireEvent("columnmove", oldIndex, newIndex);
			return true;
		}
		return false;
	}
});

Ext.treegrid.GridView.ColumnDragZone = function(treegrid, hd) {
	Ext.treegrid.GridView.ColumnDragZone.superclass.constructor.call(this, treegrid, hd, null);
	this.proxy.el.addClass('x-treegrid-col-dd');
};

Ext.extend(Ext.treegrid.GridView.ColumnDragZone, Ext.treegrid.HeaderDragZone, {
	handleMouseDown: function(e) {
	},

	callHandleMouseDown: function(e) {
		Ext.treegrid.GridView.ColumnDragZone.superclass.handleMouseDown.call(this, e);
	}
});

Ext.treegrid.SplitDragZone = function(treegrid, hd, hd2) {
	this.treegrid = treegrid;
	this.view = treegrid.getView();
	this.proxy = this.view.resizeProxy;
	Ext.treegrid.SplitDragZone.superclass.constructor.call(this, hd,
				"gridSplitters" + this.treegrid.getGridEl().id, {
					dragElId: Ext.id(this.proxy.dom), resizeFrame: false
				});
	this.setHandleElId(Ext.id(hd));
	this.setOuterHandleElId(Ext.id(hd2));
	this.scroll = false;
};

Ext.extend(Ext.treegrid.SplitDragZone, Ext.dd.DDProxy, {
	fly: Ext.Element.fly,

	b4StartDrag: function(x, y) {
		this.view.headersDisabled = true;
		this.proxy.setHeight(this.view.mainWrap.getHeight());
		var colModel = this.treegrid.getColumnModel();
		var w = colModel.getColumnWidth(this.cellIndex);
		var minw = Math.max(w - this.treegrid.minColumnWidth, 0);
		this.resetConstraints();
		this.setXConstraint(minw, 1000);
		this.setYConstraint(0, 0);
		this.minX = x - minw;
		this.maxX = x + 1000;
		this.startPos = x;
		Ext.dd.DDProxy.prototype.b4StartDrag.call(this, x, y);
	},

	handleMouseDown: function(e) {
		ev = Ext.EventObject.setEvent(e);
		var t = this.fly(ev.getTarget());
		if (t.hasClass("x-treegrid-split")) {
			this.cellIndex = this.view.getCellIndex(t.dom);
			this.split = t.dom;
			var colModel = this.treegrid.getColumnModel();
			if (colModel.isResizable(this.cellIndex) && !colModel.isFixed(this.cellIndex)) {
				Ext.treegrid.SplitDragZone.superclass.handleMouseDown.apply(this, arguments);
			}
		}
	},

	endDrag: function(e) {
		this.view.headersDisabled = false;
		var endX = Math.max(this.minX, Ext.lib.Event.getPageX(e));
		var diff = endX - this.startPos;
		var colModel = this.treegrid.getColumnModel();
		this.view.onColumnSplitterMoved(this.cellIndex, colModel.getColumnWidth(this.cellIndex) + diff);
	},

	autoOffset: function() {
		this.setDelta(0, 0);
	}
});

Ext.treegrid.GridPanel = Ext.extend(Ext.Panel, {
	minColumnWidth: 25,
	trackMouseOver: true,
	enableDragDrop: false,
	enableInnerDragDrop: false,
	dragDropMode: "Normal",
	enableColumnMove: true,
	enableColumnHide: true,
	enableHdMenu: true,
	stripeRows: true,
	hideRowBorders: false,
	stripedRowCss: "x-treegrid-row-alt",
	view: null,
	deferRowRender: true,
	rendered: false,
	viewReady: false,
	stateEvents: ["columnmove", "columnresize", "sortchange"],
	selectionMode: "MultiRows",
	useDefaultLayout: false,
	dropMode: "Move",
	quickViewMode: "Columns",

	initComponent: function() {
		Ext.treegrid.GridPanel.superclass.initComponent.call(this);
		if (this.enableInnerDragDrop == true) {
			this.enableDragDrop = true;
		}
		this.addEvents(
			"click",
			"dblclick",
			"mousedown",
			"mouseup",
			"mouseover",
			"mouseout",
			"keypress",
			"keydown",
			"cellmousedown",
			"rowmousedown",
			"headermousedown",
			"celldblclick",
			"rowclick",
			"rowdblclick",
			"headerclick",
			"headerdblclick",
			"headercontextmenu",
			"columnresize",
			"columnmove",
			"sortchange",
			"nodecontextmenu",
			"nodecheck"
		);
	},

	initSummaryPlugin: function(){
		var summary = new Ext.treegrid.Summary({dataSource: this.dataSource}); 
		if (this.plugins){
			if (!Ext.isArray(this.plugins)) {
				var pluginArray = new Array();
				pluginArray.push(this.plugins);
				pluginArray['summary'] = summary;
				this.plugins = pluginArray;
			}
		} else {
			this.plugins = new Array();
		}
		this.plugins['summary'] = summary;
		this.initPlugin(this.plugins['summary']);
	},

	onRender: function(ct, position) {
		Ext.treegrid.GridPanel.superclass.onRender.call(this, ct, position);
		var body = this.body;
		this.el.addClass('x-treegrid-panel');
		this.el.addClass('x-tree');
		body.addClass('x-treegrid-panel-body');
		body.on("click", this.onClick, this);
		body.on("keydown", this.onKeyDown, this);
		this.relayEvents(this.el, ["mousedown", "mouseup", "mouseover", "mouseout", "keypress"]);
	},

	initEvents: function() {
		Ext.treegrid.GridPanel.superclass.initEvents.call(this);
	},

	initStateEvents: function() {
		Ext.treegrid.GridPanel.superclass.initStateEvents.call(this);
		var columnModel = this.getColumnModel();
		if (!columnModel) {
			return;
		}
		columnModel.on('hiddenchange', this.saveState, this, { delay: 100 });
	},

	applyState: function(state) {
		var cm = this.treegrid.getColumnModel();
		var cs = state.columns;
		if (cs) {
			for (var i = 0, len = cs.length; i < len; i++) {
				var s = cs[i];
				var c = cm.getColumnByName(s.name);
				if (c) {
					c.isVisible = s.isVisible;
					c.width = s.width;
					var oldIndex = cm.getIndexByName(s.name);
					if (oldIndex != i) {
						cm.moveColumn(oldIndex, i);
					}
				}
			}
		}
		if (state.sort) {
			this.store[this.store.remoteSort ? 'setDefaultSort' : 'sort'](state.sort.field, state.sort.direction);
		}
	},

	getState: function() {
		var o = { columns: [] };
		var columnModel = this.getColumnModel();
		for (var i = 0, c; c = columnModel.config[i]; i++) {
			o.columns[i] = {
				id: c.name,
				width: c.width
			};
			if (!c.isVisible) {
				o.columns[i].isVisible = false;
			}
		}
		if (this.store) {
		var ss = this.store.getSortState();
		if (ss) {
			o.sort = ss;
		}
		}
		return o;
	},

	reconfigure: function(store, columnModel) {
		this.view.bind(store, columnModel);
		this.store = store;
		this.columnModel = columnModel;
		if (this.rendered) {
			this.view.refresh(true);
		}
	},

	onKeyDown: function(e) {
		this.fireEvent("keydown", e);
	},

	onHandleContextMenu: function(e) {
		this.selModel.onHandleContextMenu(e);
	},

	onDestroy: function() {
		if (this.rendered) {
			if (this.loadMask) {
				this.loadMask.destroy();
			}
			var c = this.body;
			if (c) {
				c.removeAllListeners();
			}
			if (this.view) {
				this.view.destroy();
			}
			this.contextMenu.destroy();
			if (c) {
				c.update("");
			}
		}
		var columnModel = this.getColumnModel();
		if (columnModel) {
			columnModel.purgeListeners();
		}
		Ext.treegrid.GridPanel.superclass.onDestroy.call(this);
	},

	processEvent: function(name, e) {
		this.fireEvent(name, e);
		var t = e.getTarget();
		var v = this.view;
		var header = v.findHeaderIndex(t);
		if (header !== false) {
			this.fireEvent("header" + name, this, header, e);
		} 
	},

	onClick: function(e) {
		
	},

	onMouseDown: function(e) {
		this.processEvent("mousedown", e);
	},

	onDblClick: function(e) {
		if (!Ext.get(e.target).hasClass("scrollgeneric")){
			this.processEvent("dblclick", e);
		}	
	},

	addControl: function(config, portalType) {
		// TODO Do nothing
	},

	removeControl: function(contolName, portalType) {
		// TODO Do nothing
	},

	walkCells: function(row, col, step, fn, scope) {
		var cm = this.getColumnModel(), clen = cm.getColumnCount();
		var ds = this.store, rlen = ds.getCount(), first = true;
		if (step < 0) {
			if (col < 0) {
				row--;
				first = false;
			}
			while (row >= 0) {
				if (!first) {
					col = clen - 1;
				}
				first = false;
				while (col >= 0) {
					if (fn.call(scope || this, row, col, cm) === true) {
						return [row, col];
					}
					col--;
				}
				row--;
			}
		} else {
			if (col >= clen) {
				row++;
				first = false;
			}
			while (row < rlen) {
				if (!first) {
					col = 0;
				}
				first = false;
				while (col < clen) {
					if (fn.call(scope || this, row, col, cm) === true) {
						return [row, col];
					}
					col++;
				}
				row++;
			}
		}
		return null;
	},

	getSelections: function() {
		return this.selModel.getSelections();
	},

	onResize: function() {
		if (this.viewReady) {
			var view = this.view;
			view.updateScroll();
			view.layout();
		}
	},

	getGridEl: function() {
		return this.body;
	},

	getGridBodyEl: function() {
		return this.tbar ? this.getGridEl().dom.childNodes[1] : this.getGridEl().dom.firstChild;
	},

	stopEditing: function() { },

	getSelectionModel: function() {
		return this.selModel;
	},

	getStore: function() {
		return this.store;
	},

	getColumnModel: function() {
		return this.columnModel;
	},

	getView: function() {
		if (!this.view) {
			this.view = new Ext.treegrid.GridView(this.viewConfig);
		}
		return this.view;
	},

	hasQuickView: function(){
		return (this.quickViewMode != 'None' && this.dataSource.structure.quickViewColumns && this.dataSource.structure.quickViewColumns.length > 0);
	}

});

Ext.reg('treegrid', Ext.treegrid.GridPanel);

Ext.treegrid.EditorGridPanel = Ext.extend(Ext.treegrid.GridPanel, {
	clicksToEdit: 2,
	isEditor: true,
	detectEdit: false,
	trackMouseOver: false,
	enableEditing: false,

	initComponent: function() {
		Ext.treegrid.EditorGridPanel.superclass.initComponent.call(this);
		this.activeEditor = null;
		this.addEvents(
			"beforeedit",
			"afteredit",
			"validateedit"
		);
	},

	initEvents: function() {
		Ext.treegrid.EditorGridPanel.superclass.initEvents.call(this);
		this.initEditing();
	},

	initEditing: function() {
		if (!this.enableEditing) {
			return;
		}
		if (this.clicksToEdit == 1) {
			this.on("cellselect", this.onCellDblClick, this);
		} else {
			if (this.clicksToEdit == 'auto' && this.view.mainBody) {
				this.view.mainBody.on("mousedown", this.onAutoEditClick, this);
			}
			this.on("celldblclick", this.onCellDblClick, this);
		}
		this.getGridEl().addClass("xedit-treegrid");
	},

	onCellDblClick: function(g, row, col) {
		this.startEditing(row, col);
	},

	onAutoEditClick: function(e, t) {
		if (e.button !== 0) {
			return;
		}
		var row = this.view.findRowIndex(t);
		var col = this.view.findCellIndex(t);
		if (row !== false && col !== false) {
			this.stopEditing();
			if (this.selModel.getSelectedCell) {
				var sc = this.selModel.getSelectedCell();
				if (sc && sc.cell[0] === row && sc.cell[1] === col) {
					this.startEditing(row, col);
				}
			} else {
				if (this.selModel.isSelected(row)) {
					this.startEditing(row, col);
				}
			}
		}
	},

	onEditComplete: function(ed, value, startValue) {
		this.editing = false;
		this.activeEditor = null;
		ed.un("specialkey", this.selModel.onEditorKey, this.selModel);
		if (String(value) !== String(startValue)) {
			var e = {
				eventname: "editcomplete",
				treegrid: this,
				field: ed.colName,
				originalValue: startValue,
				value: value,
				displayValue: String(ed.field.getDisplayValue()),
				cancel: false
			};
			if (this.fireEvent("validateedit", e) !== false && !e.cancel) {
				delete e.cancel;
				this.fireEvent("afteredit", e);
				var colModel = this.getColumnModel();
				var colIndex = colModel.getIndexByName(ed.colName);
				ed.node.setEditedValue(e.displayValue, colIndex);
				this.dataSource.activeRow.setColumnValue(ed.colName, value);
			}
		}
		var cell = this.getEditedCell(ed.node, ed.colName);
		Ext.get(cell).removeClass("x-cell-editing");
		this.focus();
	},

	startEditing: function(node, colName, withChange) {
		if (!this.enableEditing) {
			return;
		}
		this.stopEditing();
		var columnModel = this.getColumnModel();
		var colIndex = columnModel.getIndexByName(colName);
		if (columnModel.isCellEditable(colIndex)) {
			this.dataSource.setActiveRow(node.id);
			var value = this.dataSource.activeRow.getColumnValue(colName) || '';
			var e = {
				treegrid: this,
				value: value,
				cancel: false
			};
			if (this.fireEvent("beforeedit", e) !== false && !e.cancel) {
				this.editing = true;
				var ed = columnModel.getColumnEditor(node, colName);
				if (!ed) {
					return;
				}
				if (!ed.rendered) {
					ed.render(this.view.getEditorParent());
					ed.el.dom.style.overflow = 'hidden';
				}
				(function() {
					ed.colName = colName;
					ed.node = node;
					ed.on("complete", this.onEditComplete, this, { single: true });
					ed.on("specialkey", this.selModel.onEditorKey, this.selModel);
					this.activeEditor = ed;
					var cell = this.getEditedCell(node, colName);
					ed.startEdit(cell.firstChild, value);
					Ext.get(cell).addClass("x-cell-editing");
					var dataValueType = columnModel.getColumnByName(colName).dataValueType;
					if (withChange && (dataValueType.name == "Boolean")) {
						ed.field.setValue(!ed.field.getValue());
					}
				}).defer(10, this);
			}
		}
	},

	setEnableEditing: function(enable) {
		this.stopEditing(true);
		this.enableEditing = enable;
	},

	stopEditing: function(cancel) {
		if (!this.enableEditing) {
			return;
		}
		if (this.activeEditor) {
			this.activeEditor[cancel === true ? 'cancelEdit' : 'completeEdit']();
		}
		this.activeEditor = null;
	},

	getEditedCell: function(node, colName) {
		var elNode = node.ui.elNode;
		var colModel = this.getColumnModel();
		var colIndex = colModel.getIndexByName(colName);
		var colPosition = colModel.getColumnPosition(colIndex);
		return elNode.rows[0].cells[colPosition];
	},

	onDestroy: function() {
		var columnModel = this.getColumnModel();
		if (this.rendered && columnModel) {
			var cols = columnModel.config;
			for (var i = 0, len = cols.length; i < len; i++) {
				var c = cols[i];
				Ext.destroy(c.editor);
			}
		}
		Ext.treegrid.EditorGridPanel.superclass.onDestroy.call(this);
	}
});

Ext.reg('editorgrid', Ext.treegrid.EditorGridPanel);

Ext.treegrid.Summary = function(config) {
	Ext.apply(this, config);
	this.dataSource.on("beforeloadsummary", this.onDataSourceBeforeLoadSummary, this);
	this.dataSource.on("summaryloaded", this.onDataSourceSummaryLoaded, this);
	this.dataSource.on("summaryloadexception", this.onDataSourceSummaryLoadException, this);
};

Ext.extend(Ext.treegrid.Summary, Ext.util.Observable, {
	summaryCls: "x-treegrid-summary",
	noSummaryType: "None",

	init: function(treegrid) {
		this.treegrid = treegrid;
		this.view = treegrid.getView();
		var v = this.view;
		v.doSummary = this.doSummary.createDelegate(this);
		v.afterMethod('onColumnWidthUpdated', this.doWidth, this);
		v.afterMethod('onAllColumnWidthsUpdated', this.doAllWidths, this);
		v.afterMethod('onColumnDeleted', this.doDeleteSummaryColumn, this);
		v.afterMethod('onColumnMoved', this.doMove, this);
		v.afterMethod('onUpdate', this.doUpdate, this);
		v.afterMethod('onRemove', this.doRemove, this);
		if (!this.rowTpl) {
			this.rowTpl = new Ext.Template(
								'<div class="summary-inner">',
								'<table class="x-treegrid-summary-table" border="0" cellspacing="0" cellpadding="0" style="{style}">',
										'<tbody><tr>{cells}</tr></tbody>',
									'</table>',
								'</div>'
						);
			this.rowTpl.disableFormats = true;
		}
		this.rowTpl.compile();
		if (!this.cellTpl) {
			this.cellTpl = new Ext.Template(
								'<td class="x-treegrid-summary x-treegrid-cell x-treegrid-cell-{name} {lastColumn}" style="{style}">',
									'<div style="position:relative">',
									'<div class="x-treegrid-cell-inner">',
										'<img class="x-treegrid-summary-icon" src="' + Ext.BLANK_IMAGE_URL + '" />',
										'<span>{title}</span>',
										'<b>{value}</b>',
									'</div>',
									'<a class="x-treegrid-summary-btn" href="#"></a>',
								'</td>'
						);
			this.cellTpl.disableFormats = true;
		}
		this.cellTpl.compile();
	},

	toggleSummaries: function(visible) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			if (visible === undefined) {
				return;
			}
			var display = visible ? '' : 'none';
			summaryNode.parentNode.style.display = display;
			if (visible) {
				this.requestSummaries();
			}
		} else {
			this.view.renderSummary();
		}
		var treegrid = this.treegrid;
		treegrid.isSummaryVisible = visible;
		treegrid.setProfileData('isSummaryVisible', visible);
	},

	render: function() {
		var treegrid = this.treegrid;
		var columns = treegrid.getColumns();
		this.syncSummaryColumnWidth(columns);
		var buf = [], p = {}, last = columns.length - 1;
		for (var i = 0, len = columns.length; i < len; i++) {
			column = columns[i];
			if (!column.isVisible) {
				continue;
			}
			p.name = column.name;
			p.style = column.style;
			p.lastColumn = (i == last) ? 'last-column' : '';
			p.value = "";
			p.title = "&#160";
			buf[buf.length] = this.cellTpl.apply(p);
		}
		return this.rowTpl.apply({
			style: 'width:' + this.view.getTotalWidth() + ';',
			cells: buf.join('')
		});
	},

	syncSummaryColumnWidth: function(columns) {
		for (var i = 0, len = columns.length; i < len; i++) {
			columns[i].style = "width:" + this.view.getColumnWidth(i) + ";";
		}
	},

	doSummary: function() {
		var buf = new Array();
		buf.push(this.render());
		return buf;
	},

	hasSummary: function() {
		var columns = this.treegrid.getColumns();
		var column;
		for (var i = 0, count = columns.length; i < count; i++) {
			column = columns[i];
			var summaryType = column.summaryAggregationType || this.noSummaryType;
			var isVisible = (column.isVisible !== false);
			if ((isVisible) && (summaryType != this.noSummaryType)) {
				return true;
			}
		}
		return false;
	},

	doWidth: function(col, w, tw) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			var position = this.view.getColumnPosition(col);
			this.view.updateTreeColumn(summaryNode, position, w, tw, '');
		}
	},

	doAllWidths: function(ws, tw) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			var columnModel = this.treegrid.getColumnModel();
			var position;
			var view = this.view;
			for (var i = 0, count = columnModel.getColumnCount(); i < count; i++) {
				if (columnModel.isVisible(i)) {
					position = view.getColumnPosition(i);
					view.updateTreeColumn(summaryNode, position, ws[i], tw, '');
				}
			}
		}
	},

	doHidden: function(col, w, tw, display) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			var position = this.view.getColumnPosition(col);
			this.view.updateTreeColumn(summaryNode, position, w, tw, display);
		}
	},

	doDeleteSummaryColumn: function(position) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			var view = this.view;
			var totalWidth = view.getTotalWidth();
			var innerSummary, summaryColumn;
			view.applyDomWidth(summaryNode.firstChild, totalWidth);
			innerSummary = summaryNode.firstChild.rows[0];
			summaryColumn = innerSummary.childNodes[position];
			innerSummary.removeChild(summaryColumn);
		}
	},

	doMove: function(oldPosition, newPosition) {
		var summaryNode = this.getSummaryNode();
		if (summaryNode) {
			var summaryTableNode = summaryNode.firstChild;
			this.view.moveRowColumns(summaryTableNode, oldPosition, newPosition);
		}
	},

	getSummaryNode: function() {
		var summaryNode = null;
		if (this.view.el) {
			summaryNode = this.view.summary.dom.firstChild;
		}
		return summaryNode;
	},

	getSummaryColumns: function() {
		var summary = this.getSummaryNode();
		var summaryColumns = null;
		if (summary) {
			summaryColumns = summary.childNodes[0].childNodes[0].childNodes[0].childNodes;
		}
		return summaryColumns;
	},

	getSummaryColumn: function(index) {
		var summaryColumns = this.getSummaryColumns();
		var summaryColumn = null;
		if (summaryColumns) {
			summaryColumn = summaryColumns[index];
		}
		return summaryColumn;
	},

	refreshSummaryByIndex: function(index, value) {
		var position = this.view.getColumnPosition(index);
		var summaryColumn = this.getSummaryColumn(position);
		if (summaryColumn) {
			var treegrid = this.treegrid;
			var columnModel = treegrid.getColumnModel();
			var column = columnModel.getColumn(index);
			value = Ext.isEmpty(value) ? "" : value;
			var title = this.getSummaryTitle(column.summaryAggregationType);
			summaryColumn.getElementsByTagName('span')[0].innerHTML = Ext.util.Format.htmlEncode(title) || "&#160";
			var dataValueType = column.dataValueType;
			var summaryValue;
			if (dataValueType.isNumeric) {
				var decimalPrecision = 0;
				if (dataValueType.name != 'Integer') {
					decimalPrecision = dataValueType.precision || 2;
				}
				var displayOptions = {
					decimalPrecision: decimalPrecision,
					showTrailingZeros: true
				};
				summaryValue = Terrasoft.Math.getDisplayValue(Ext.util.Format.htmlEncode(value), displayOptions);
			} else {
				summaryValue = value;
			}
			summaryColumn.getElementsByTagName('b')[0].innerHTML = summaryValue;
		}
	},

	findSummaryCell: function(el) {
		var cell = this.view.findCell(el);
		return cell && this.view.fly(cell).hasClass(this.summaryCls) ? cell : null;
	},

	initSummaryMenus: function() {
		var columnModel = this.treegrid.getColumnModel();
		for (var i = 0, count = columnModel.getColumnCount(); i < count; i++) {
			column = columnModel.config[i];
			column.summaryMenu = this.getSummaryMenu(column);
		}
	},

	getSummaryMenu: function(column) {
		var menu = new Ext.menu.Menu({ id: "summary-menu-" + column.name });
		var groupName = "summary-" + column.name;
		if (!column.aggregationType) {
			switch (column.dataValueType.name) {
				case 'Integer':
				case 'Float1':
				case 'Float2':
				case 'Float3':
				case 'Float4':
				case 'Money':
					menu.add(
							{ id: "Sum", caption: this.getAggregationTitleByType("Sum"), checked: false, group: groupName },
							{ id: "Count", caption: this.getAggregationTitleByType("Count"), checked: false, group: groupName },
							{ id: "Max", caption: this.getAggregationTitleByType("Max"), checked: false, group: groupName },
							{ id: "Min", caption: this.getAggregationTitleByType("Min"), checked: false, group: groupName },
							{ id: "Avg", caption: this.getAggregationTitleByType("Avg"), checked: false, group: groupName }
						);
					break;
				case 'Date':
				case 'Time':
				case 'DateTime':
					menu.add(
							{ id: "Count", caption: this.getAggregationTitleByType("Count"), checked: false, group: groupName },
							{ id: "Max", caption: this.getAggregationTitleByType("Max"), checked: false, group: groupName },
							{ id: "Min", caption: this.getAggregationTitleByType("Min"), checked: false, group: groupName }
						);

					break;
				default:
					menu.add({ id: "Count", caption: this.getAggregationTitleByType("Count"), checked: false, group: groupName });
			}
			if (column.summaryAggregationType) {
				this.checkCurrentSummary(menu.items, column.summaryAggregationType);
			}
		}
		menu.add("-", { id: this.noSummaryType, caption: this.getAggregationTitleByType(this.noSummaryType), checked: true, group: groupName });
		menu.on("itemclick", this.handleSummaryMenuClick, this);
		return menu;
	},

	checkCurrentSummary: function(menuItems, summaryType) {
		var item;
		for (var i = 0, count = menuItems.length; i < count; i++) {
			item = menuItems.items[i];
			if (item.id == summaryType) {
				item.setChecked(true);
			}
		}
	},

	handleSummaryDown: function(e, t) {
		if (Ext.fly(t).hasClass('x-treegrid-summary-btn')) {
			e.stopEvent();
			this.onSymmaryButtonClick(t);
		} else if (Ext.fly(t).hasClass('x-treegrid-summary-icon')) {
			e.stopEvent();
			this.onSummaryIconClick(t);
		}
	},

	getColumnSummaryMenu: function(t) {
		var summary = this.findSummaryCell(t);
		this.summaryCtxIndex = this.view.getCellIndex(summary);
		Ext.fly(summary).addClass('x-treegrid-summary-menu-open');
		var columnModel = this.treegrid.getColumnModel();
		var summaryMenu = columnModel.config[this.summaryCtxIndex].summaryMenu;
		summaryMenu.on("hide", function() {
			Ext.fly(summary).removeClass('x-treegrid-summary-menu-open');
		}, this, { single: true });
		return summaryMenu;
	},

	onContextMenu: function(e, t) {
		e.stopEvent();
		var summaryMenu = this.getColumnSummaryMenu(t);
		summaryMenu.showAt(e.xy);
	},

	onSymmaryButtonClick: function(t) {
		var summaryMenu = this.getColumnSummaryMenu(t);
		summaryMenu.show(t, "br-tl?");
	},

	onSummaryIconClick: function(t) {
		this.refreshSummaries();
	},

	refreshSummaries: function() {
		this.enableRefreshState(false);
		this.requestSummaries();
	},

	handleSummaryOver: function(e, t) {
		var summary = this.findSummaryCell(t);
		if (summary) {
			this.activeSummary = summary;
			this.activeSummaryIndex = this.view.getCellIndex(summary);
			var fly = this.view.fly(summary);
			this.activeSummaryRegion = fly.getRegion();
			var colModel = this.treegrid.getColumnModel();
			if (!colModel.isSummaryMenuDisabled(this.activeSummaryIndex)) {
				fly.addClass("x-treegrid-summary-over");
			}
		}
	},

	handleSummaryOut: function(e, t) {
		var summary = this.findSummaryCell(t);
		if (summary && (!Ext.isIE || !e.within(summary, true))) {
			this.activeSummary = null;
			this.view.fly(summary).removeClass("x-treegrid-summary-over");
			summary.style.cursor = '';
		}
	},

	handleSummaryMenuClick: function(item) {
		var index = this.summaryCtxIndex;
		var summaryType = item.id;
		this.setColumnAggregationType(index, summaryType);
		return true;
	},

	setColumnAggregationType: function(index, aggregationType) {
		var treegrid = this.treegrid;
		var columnModel = treegrid.getColumnModel();
		var column = columnModel.getColumn(index);
		var callback;
		if (aggregationType == this.noSummaryType) {
			callback = this.refreshSummaryByIndex.createDelegate(this, [index, ""]);
		} else {
			callback = this.requestSummaries.createDelegate(this);
		}
		var dataSource = treegrid.dataSource;
		colConfig = new Object;
		colConfig[column.name] = {
			summaryAggregationType: aggregationType
		};
		dataSource.updateStructure({
			columns: colConfig,
			attribute: {
				callback: callback
			}
		});
	},

	requestSummaries: function() {
		if (this.hasSummary()) {
			this.dataSource.loadSummary();
		}
	},

	onDataSourceBeforeLoadSummary: function(dataSource, cfg) {
		this.enableLoadingState(true);
	},

	onDataSourceSummaryLoaded: function(dataSource, data) {
		this.lastData = data;
		this.view.clearSummary();
		if (data) {
			this.processSummariesResponse(data);
		}
		this.initEvents();
	},

	onDataSourceSummaryLoadException: function(dataSource, responseText) {
		this.enableLoadingState(false);
	},

	processSummariesResponse: function(summaries) {
		var column, summaryValue;
		var columnModel = this.treegrid.getColumnModel();
		for (var i = 0, count = columnModel.getColumnCount(); i < count; i++) {
			column = columnModel.getColumn(i);
			var typeName = column.dataValueType.name;
			summaryValue = summaries[column.name];
			if (!Ext.isEmpty(column.summaryAggregationType) && !Ext.isEmpty(summaryValue)) {
				if (column.summaryAggregationType != "Count") {
					if (typeName == "DateTime") {
						summaryValue = Ext.util.Format.date(summaryValue, Ext.util.Format.getDateTimeFormat());
					} else if (typeName == "Date") {
						summaryValue = Ext.util.Format.date(summaryValue, Ext.util.Format.getDateFormat());
					} else if (typeName == "Time") {
						summaryValue = Ext.util.Format.date(summaryValue, Ext.util.Format.getTimeFormat());
					}
				}
				this.refreshSummaryByIndex(i, summaryValue);
				this.enableLoadingState(false, i);
			}
		}
	},

	setSummaryColumnState: function(stateClass, enabled, columnIndexes) {
		var indexesArray = new Array();
		var columnModel = this.treegrid.getColumnModel();
		if (Ext.isArray(columnIndexes)) {
			indexesArray = columnIndexes;
		} else if (!columnIndexes) {
			var summaryType;
			for (var i = 0, count = columnModel.getColumnCount(); i < count; i++) {
				summaryType = columnModel.config[i].summaryAggregationType;
				if (columnModel.isVisible(i) && summaryType && (summaryType != this.noSummaryType)) {
					indexesArray.push(i);
				}
			}
		} else {
			indexesArray.push(columnIndexes);
		}
		for (var i = 0, count = indexesArray.length; i < count; i++) {
			var position = this.view.getColumnPosition(indexesArray[i]);
			var summaryColumn = this.getSummaryColumn(position);
			if (summaryColumn) {
				var summaryCell = Ext.get(summaryColumn.firstChild);
				if (stateClass == "loading") {
					columnModel.enableSummaryMenu(indexesArray[i], !enabled);
				}
				if (enabled) {
					summaryCell.addClass(stateClass);
				} else {
					summaryCell.removeClass(stateClass);
				}
			}
		}
	},

	enableLoadingState: function(enabled, columnIndexes) {
		var stateClass = "loading";
		this.setSummaryColumnState(stateClass, enabled, columnIndexes);
	},

	enableRefreshState: function(enabled, columnIndexes) {
		var stateClass = "refresh";
		this.setSummaryColumnState(stateClass, enabled, columnIndexes);
	},

	initEvents: function() {
		this.view.summary.on("mouseover", this.handleSummaryOver, this);
		this.view.summary.on("mouseout", this.handleSummaryOut, this);
		this.innerSummary = Ext.fly(this.view.summary.dom.firstChild);
		this.innerSummary.on("click", this.handleSummaryDown, this);
		this.innerSummary.on("contextmenu", this.onContextMenu, this);
		this.initSummaryMenus();
	},

	getAggregationTitleByType: function(type) {
		return Ext.StringList('WC.TreeGrid').getValue('AggregationType.' + type);
	},

	getSummaryTitle: function(type) {
		if ((type) && (type != this.noSummaryType)) {
			return this.getAggregationTitleByType(type) + ": ";
		} else {
			return "";
		}
	},

	doUpdate: function(ds, row) {
		return;
	},

	doRemove: function(ds, row, index, isUpdate) {
		if (!isUpdate) {
			return;
		}
	}

});

Terrasoft.GridPanel = function(config) {
	this.selectedIds = {};
	this.memoryIDField = 'id';

	Ext.apply(this, config);
	this.addEvents("editcompleted");
	Terrasoft.GridPanel.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.GridPanel, Ext.treegrid.EditorGridPanel, {
	footerVisible: true,
	quickFilterVisible: true,
	toolbarVisible: true,
	width: 400,
	height: 200,
	menuConfig: [],

	initComponent: function() {
		if (this.footerVisible){
			this.initFooter();
		}
		Terrasoft.GridPanel.superclass.initComponent.call(this);
	},

	memoryReConfigure: function() {
		this.store.on('clear', this.onMemoryClear, this);
		this.store.on('datachanged', this.memoryRestoreState, this);
	},

	onMemorySelect: function(sm, idx, rec) {
		var id = this.getRecId(rec);
		var absIndex = this.getAbsoluteIndex(idx);
		this.onMemorySelectId(sm, absIndex, id);
	},

	onMemorySelectId: function(sm, index, id) {
		var obj = { id: id, index: index };
		this.selectedIds[id] = obj;
	},

	getAbsoluteIndex: function(pageIndex) {
		var absIndex = pageIndex;
		if (!Ext.isEmpty(this.pbarID)) {
			if (!this.pbar) {
				this.pbar = Ext.getCmp(this.pbarID);
			}
			absIndex = ((this.pbar.getPageData().activePage - 1) * this.pbar.pageSize) + pageIndex;
		}

		return absIndex;
	},

	onMemoryDeselect: function(sm, idx, rec) {
		delete this.selectedIds[this.getRecId(rec)];
	},

	onStoreRemove: function(store, rec, idx) {
		this.onMemoryDeselect(null, idx, rec);
	},

	memoryRestoreState: function() {
		if (this.store != null) {
			var i = 0;
			var sel = [];
			var all = true;
			this.store.each(function(rec) {
				var id = this.getRecId(rec);
				if (!Ext.isEmpty(this.selectedIds[id])) {
					sel.push(i);
				}
				else {
					all = false;
				}
				++i;
			}, this);
			var silent = true;
			if (sel.length > 0) {
				if (silent) {
					this.suspendEvents();
					this.selModel.suspendEvents();
				}
				this.selModel.selectRows(sel);
				if (silent) {
					this.resumeEvents();
					this.selModel.resumeEvents();
				}
			}
			if (this.selModel.checkHeader) {
				if (all) {
					this.selModel.checkHeader();
				}
				else {
					this.selModel.uncheckHeader();
				}
			}
		}
	},

	getRecId: function(rec) {
		var id = rec.get(this.memoryIDField);
		if (Ext.isEmpty(id)) {
			id = rec.id;
		}

		return id;
	},

	onMemoryClear: function() {
		var sel = [];
		this.selectedIds = {};
	},

	initFooter: function(){
		var footer = new Terrasoft.Tools.ToolbarCollection();
		if (this.toolbarVisible) {
			var pagingToolbar = new Terrasoft.TreeGrid.PagingToolbar(this, !this.quickFilterVisible);
			footer.addItem(pagingToolbar, "pagingToolbar");
		}
		this.bbar = footer;
	},

	onNextPage: function() {
		var pagingToolbar = this.getPagingToolbar();
		if (this.root.hasNextPage != false) {
			pagingToolbar.setPage(pagingToolbar.currentPage + 1);
			this.doNextPage();
		}
	},
	
	onPrevPage: function() {
		var pagingToolbar = this.getPagingToolbar();
		if (pagingToolbar.currentPage == 1) {
			return;
		}
		pagingToolbar.setPage(pagingToolbar.currentPage - 1);
		this.doPrevPage();
	},
	
	onFirstPage: function() {
		var pagingToolbar = this.getPagingToolbar();
		if (pagingToolbar) {
			pagingToolbar.setPage(1);
		}
		this.doFirstPage();
	},
	
	onRefreshPage: function(doRefreshSummaries) {
		var pagingToolbar = this.getPagingToolbar();
		if (pagingToolbar && (pagingToolbar.currentPage == 1)) {
			this.doFirstPage(doRefreshSummaries);
		} else {
			this.doRefreshPage(doRefreshSummaries);
		}
	},

	onViewSummary: function() {
		this.view.showSummary(!this.isSummaryVisible);
	},
	
	onExportData: function() {
		this.fireEvent("exportdata");
	},

	onContextMenu: function(el, e) {
		e.stopEvent();
		this.tbmenu.showAt(e.xy);
	},
	
	getPagingToolbar: function() {
		var bottomToolbar = this.bottomToolbar;
		if (bottomToolbar) {
			return bottomToolbar.items.get("pagingToolbar");
		}	else {
			return null;
		}
	},
	
	setKeyMap: function(){
		this.keymap = new Ext.KeyMap(this.view.el, {
			key: [13, 35, 36],
			scope: this,
			fn: this.handleKeys
		});
	},

	handleKeys: function(key, e) {
		switch (key) {
			case 13:  // return key
				var rowIndex = this.selModel.last;
				var keyEvent = (e.shiftKey === true) ? "rowdblclick" : "rowclick";
				this.fireEvent(keyEvent, this, rowIndex, e);
				break;
			case 35:  // end key
				if (this.store.getCount() > 0) {
					this.selModel.selectLastRow();
					this.getView().focusRow(this.store.getCount() - 1);
				}
				break;
			case 36:  // home key
				if (this.store.getCount() > 0) {
					this.selModel.selectFirstRow();
					this.getView().focusRow(0);
				}
				break;
		}
	},

	isDirty: function() {
		if (this.store.modified.length > 0 || this.store.deleted.length > 0) {
			return true;
		}
		return false;
	},

	hasSelection: function() {
		return this.selModel.hasSelection();
	},

	clear: function(skipMarkSummaryAsWrong, leaveCurrentPage) {
		this.selModel.clearSelections(true);
		this.selModel.activeCellIndex = null;
		this.stopEditing(true);
		if (this.root) {
			this.root.removeChildren();
		}
		if (this.view) {
			delete this.view.rows;
		}
		if (!leaveCurrentPage && this.bottomToolbar) {
			var pagingToolbar = this.bottomToolbar.items.get("pagingToolbar");
			if (pagingToolbar) {
				pagingToolbar.setPage(1);
			}
		}
		if (!skipMarkSummaryAsWrong) {
			this.markSummaryAsWrong();
		}
	},

	saveMask: false,
	
	initEvents: function() {
		Terrasoft.GridPanel.superclass.initEvents.call(this);

		if (this.saveMask) {
			this.saveMask = new Terrasoft.SaveMask(this.bwrap,
			Ext.apply({ writeStore: this.store }, this.saveMask));
		}
	},

	reconfigure: function(store, columnModel) {
		Terrasoft.GridPanel.superclass.reconfigure.call(this, store, columnModel);
		if (this.saveMask) {
			this.saveMask.destroy();
			this.saveMask = new Terrasoft.SaveMask(this.bwrap,
			Ext.apply({ writeStore: store }, this.initialConfig.saveMask));
		}
	},

	onDestroy: function() {
		if (this.rendered) {
			if (this.saveMask) {
				this.saveMask.destroy();
			}
		}
		Terrasoft.GridPanel.superclass.onDestroy.call(this);
	},

	getRowsValues: function(selectedOnly) {
		if (Ext.isEmpty(selectedOnly)) {
			selectedOnly = true;
		}
		var rows = (selectedOnly ? this.selModel.getSelections() : this.store.getRange()) || [];
		var values = [];
		for (var i = 0; i < rows.length; i++) {
			var obj = {};
			if (this.store.reader.meta.id) {
				obj[this.store.reader.meta.id] = rows[i].id;
			}
			values.push(Ext.apply(obj, rows[i].data));
		}
		return values;
	},

	removeColumn: function(colIndex) {
		var colModel = this.getColumnModel();
		delete colModel.totalWidth;
		var column = colModel.getColumn(colIndex);
		var position = colModel.getColumnPosition(colIndex);
		var callback = this.view.onColumnHidden.createDelegate(this.view, [position]);
		var cfg = {
			attribute: {
				callback: callback
			}
		};
		this.dataSource.removeStructureColumns(column.uId, cfg);
	},

	updateColumnModel: function() {
		this.columnModel = new Ext.treegrid.ColumnModel({
			columns: this.dataSource.structure.columns
		});
		this.view.initColumnModelEvents();
	},

	updateColumns: function(headersToo) {
		this.updateColumnModel();
		if (headersToo === true) {
			this.view.updateHeaders();
		}
		this.viewReady = true;
		delete this.view.lastViewWidth;
		this.view.layout();
		if (this.isSummaryVisible) {
			var summary = this.getSummaryPlugin();
			var lastSummaryData = summary.lastData;
			summary.onDataSourceSummaryLoaded(this.dataSource, lastSummaryData);
		}
	},
	
	updateColumnModelAndPage: function() {
		this.updateColumnModel();
		this.onRefreshPage(true);
	},
	
	//todo реализовать
	// нужно для отображения/скрытия в дизайнере страниц
	showFooter: function(footerVisible) {
		
	},
	
	//todo реализовать
	// нужно для отображения/скрытия в дизайнере страниц
	showQuickFilter: function(quickFilterVisible) {
		
	},
	
	//todo реализовать
	// нужно для отображения/скрытия в дизайнере страниц
	showToolbar: function(toolbarVisible) {
		
	},
	
	updateScroll: function() {
		this.view.updateScroll();
	},
	
	updateOpenedQuickViews: function() {
		var nodes = this.nodeHash;
		for (nodeId in nodes) {
			var node = nodes[nodeId];
			if (node.ui.isQuickViewVisible) {
				this.quickView.show(node.ui);
			}
		}
	}
	
});

Ext.reg("terrasoftgrid", Terrasoft.GridPanel);

Ext.treegrid.TreeEventModel = function(treegrid) {
	this.treegrid = treegrid;
	this.initEvents();
};
Ext.treegrid.TreeEventModel.prototype = {
	initEvents: function() {
		var el = this.treegrid.getTreeEl();
		el.on('click', this.delegateClick, this);
		if (this.treegrid.trackMouseOver !== false) {
			el.on('mouseover', this.delegateOver, this);
			el.on('mouseout', this.delegateOut, this);
		}
		el.on('dblclick', this.delegateDblClick, this);
		el.on('contextmenu', this.delegateContextMenu, this);
	},

	getNode: function(e) {
		var t;
		var view = this.treegrid.view;
		if (t = e.getTarget(view.rowSelector, view.rowSelectorDepth)) {
			var id = Ext.fly(t, '_treeEvents').getAttributeNS('ext', 'tree-node-id');
			if (id) {
				return this.treegrid.getNodeById(id);
			}
		}
		return null;
	},

	getNodeTarget: function(e) {
		var view = this.treegrid.view;
		var t = e.getTarget(view.rowSelector, view.rowSelectorDepth);
		return t;
	},

	delegateOut: function(e, t) {
		if (!this.beforeEvent(e)) {
			return;
		}
		if (e.getTarget('.x-tree-ec-icon', 1)) {
			var n = this.getNode(e);
			this.onIconOut(e, n);
			if (n == this.lastEcOver) {
				delete this.lastEcOver;
			}
		}
		if ((t = this.getNodeTarget(e)) && !e.within(t, true)) {
			this.onNodeOut(e, this.getNode(e));
		}
	},

	delegateOver: function(e, t) {
		if (!this.beforeEvent(e)) {
			return;
		}
		if (this.lastEcOver) {
			this.onIconOut(e, this.lastEcOver);
			delete this.lastEcOver;
		}
		if (e.getTarget('.x-tree-ec-icon', 1)) {
			this.lastEcOver = this.getNode(e);
			this.onIconOver(e, this.lastEcOver);
		}
		if (t = this.getNodeTarget(e)) {
			this.onNodeOver(e, this.getNode(e));
		}
	},

	delegateClick: function(e, t) {
		if (!this.beforeEvent(e) || this.skipEvent) {
			return;
		}
		var target = Ext.get(t);
		var node = this.getNode(e);
		if (target.hasClass('x-tree-ec-icon')) {
			this.onExpandIconClick(e, node);
		} else if (target.hasClass('x-tree-cell-arrow')) {
			this.onQuickViewIconClick(e, node);
		} else if (target.hasClass('x-tree-contextmenu-mobile')) {
			this.onCellContextMenuButtonClick(e);
		} else if (target.hasClass('x-link')){
			this.onValueLinkClick(e, node);
		} else if (target.hasClass('x-treegrid-cell-icon')){
			if (node && !this.ignoreNodeClick){
				this.onNodeClick(e, node);
			}
			this.onCellIconClick(target, node);
		} else if (target.hasClass('lookup value')){
			this.onLookupValueClick(e, node);
		} else if (target.hasClass('paging value')){
			this.onPagingNodeClick(e, node);
		} else if (this.getNodeTarget(e)) {
			if (node && !this.ignoreNodeClick){
				this.onNodeClick(e, node);
			}
		} 
	},

	delegateDblClick: function(e, t) {
		if (this.beforeEvent(e) && this.getNodeTarget(e)) {
			var node = this.getNode(e);
			if (node){
				this.onNodeDblClick(e, node);
			}
		}
	},

	delegateContextMenu: function(e, t) {
		if (this.beforeEvent(e) && this.getNodeTarget(e)) {
			this.onNodeContextMenu(e, this.getNode(e));
		}
	},

	onNodeClick: function(e, node) {
		var treegrid = node.getTreeGrid();
		var selectionModel = treegrid.getSelectionModel();
		if (selectionModel){
			selectionModel.onNodeClick(node, e);
		}	
	},

	onNodeOver: function(e, node) {
		node.ui.onOver(e);
	},

	onNodeOut: function(e, node) {
		node.ui.onOut(e);
	},

	onIconOver: function(e, node) {
		node.ui.addClass('x-tree-ec-over');
	},

	onIconOut: function(e, node) {
		node.ui.removeClass('x-tree-ec-over');
	},

	onExpandIconClick: function(e, node) {
		if (node.isPaging){
			this.onPagingNodeClick(e, node);
		} else {
			node.ui.ecClick();
		}
	},
	
	onQuickViewIconClick: function(e, node) {
		node.ui.preview();
	},

	onCellContextMenuButtonClick: function(e) {
		this.treegrid.contextMenu.showAt(e.xy);
	},

	onValueLinkClick: function(e, node) {
		var valueLink = e.getTarget('.x-link', 1);
		var valueLinkId = valueLink.getAttributeNode('linkId').value;
		var treegrid = node.getTreeGrid();
		var href;
		if (!Ext.isEmpty(href = valueLink.getAttribute('href')) && (href.charAt(href.length - 1) == '#')) {
			treegrid.sendValueLinkNotification(valueLinkId, node);
			e.preventDefault();
		}
	},
	
	onCellIconClick: function(cellIcon, node) {
		var cellIconId = cellIcon.dom.getAttributeNode('iconId').value;
		var treegrid = node.getTreeGrid();
		treegrid.sendCellIconClickNotification(cellIconId, node);
	},
	
	onLookupValueClick: function(e, node){
		var treegrid = this.treegrid;
		var dataSource = treegrid.dataSource;
		var colIndex = treegrid.view.findCellIndex(e.target);
		var row = dataSource.getRow(node.id);
		var primaryColumnValue = row.getPrimaryColumnValue();
		var colModel = treegrid.getColumnModel();
		var column = colModel.getColumn(colIndex);
		var columnValue = row.getColumnValue(column.name);
		primaryColumnValue = Ext.encode(primaryColumnValue);
		columnValue = Ext.encode(columnValue);
		columnName = Ext.encode(column.name);
		var ctrlKey = e.ctrlKey ? e.ctrlKey : false;
		treegrid.fireEvent("lookupvalueclick", primaryColumnValue, columnName, columnValue, ctrlKey);
	},
	
	onPagingNodeClick: function(e, node){
		node.parentNode.addNextPage();
	},

	onCheckboxClick: function(e, node) {
		node.ui.onCheckChange(e);
	},

	onNodeDblClick: function(e, node) {
		node.ui.onDblClick(e);
	},

	onNodeContextMenu: function(e, node) {
		if (node) {
			node.ui.onContextMenu(e);
		}
	},

	beforeEvent: function(e) {
		if (this.disabled) {
			e.stopEvent();
			return false;
		}
		return true;
	},

	disable: function() {
		this.disabled = true;
	},

	enable: function() {
		this.disabled = false;
	}
};

Terrasoft.TreeGrid = Ext.extend(Terrasoft.GridPanel, {
	animate: false,
	lines: true,
	deferHeight: false,
	hlDrop: Ext.enableFx,
	pathSeparator: "/",
	enableContextMenu: true,
	showAutoWidthMenu: true,
	showMultiLineMenu: true,
	showSummariesMenu: true,
	isSummaryVisible: false,
	isMultilineMode: true,
	allowExportData: true,
	isColumnAutowidth: true,
	allowCustomSelection: false,
	initialized: false,

	initComponent: function () {
		Terrasoft.TreeGrid.superclass.initComponent.call(this);
		this.initSelectionModel();
		if (this.dataSource) {
			this.initDataSourceEvents();
		}
	},

	initialize: function () {
		this.addEvents(
			"append",
			"remove",
			"movenode",
			"insert",
			"beforeappend",
			"beforeremove",
			"beforemovenode",
			"beforeinsert",
			"beforeload",
			"load",
			"textchange",
			"beforeexpandnode",
			"beforecollapsenode",
			"expandnode",
			"disabledchange",
			"collapsenode",
			"beforeclick",
			"checkchange",
			"beforechildrenrendered",
			"startdrag",
			"enddrag",
			"dragdrop",
			"beforenodesdrop",
			"nodesdrop",
			"nodedragover",
			"selectionchange",
			"linkclick",
			"celliconclick",
			"columnhidden",
			"lookupvalueclick",
			"preparelookupfilter",
			"beforesetcolumns",
			"setcolumns",
			"setquickviewcolumns",
			"exportdata",
			"notifyout"
		);
		this.initiSelectionHiddenField();
		if (this.singleExpand) {
			this.on("beforeexpandnode", this.restrictExpand, this);
		}
		this.afterInit(this.config);
		this.initView();
		this.getSelectionModel().init();
		this.setKeyMap();
		this.initDragAndDrop();
		this.initSummaryPlugin();
		this.view.setElPosition();
		this.view.updateScrollerElementHeight();
		this.view.on("dblclick", this.onDblClick, this);
		if (!this.eventModel) {
			this.eventModel = new Ext.treegrid.TreeEventModel(this);
		}
		if (this.hasQuickView) {
			this.quickView = new Terrasoft.treegrid.QuickView({ mode: this.quickViewMode, treegrid: this });
		}
		this.createRootNode();
		this.initializeQuickFilter();
		this.setPagingToolbarItems();
		this.initialized = true;
	},

	afterRender: function () {
		Terrasoft.TreeGrid.superclass.afterRender.call(this);
		if (!this.initialized && this.columnModel) {
			this.initialize();
			if (this.deferredData) {
				this.applyDeferredData();
			}
		}
	},

	initiSelectionHiddenField: function () {
		if (Ext.isEmpty(this.selModelHidden)) {
			this.selModelHidden = this.id + '_SM';
		}
		this.hField = Ext.get(this.selModelHidden);
		if (!this.hField) {
			var hd = document.createElement('input');
			hd.type = 'hidden';
			hd.id = this.selModelHidden;
			hd.name = this.selModelHidden;
			this.el.dom.appendChild(hd);
			this.hField = Ext.get(hd.id);
		}
	},

	initSelectionModel: function () {
		var config = this.disableSelection ? { selectRow: Ext.emptyFn} : {};
		config.treegrid = this;
		switch (this.selectionMode) {
			case "SingleRow":
				this.selModel = new Terrasoft.treegrid.SingleRowSelectionModel(config);
				break;
			case "MultiRows":
				this.selModel = new Terrasoft.treegrid.MultiRowsSelectionModel(config);
				break;
		}
		this.relayEvents(this.selModel, ["rowselect", "rowdeselect"]);
	},

	initView: function () {
		var view = this.getView();
		view.init(this);
		view.render();
		this.innerCt = this.view.mainBody;
		view.afterRender();
	},

	initDataSourceEvents: function () {
		this.dataSource.on("structureloaded", this.onDataSourceStructureLoaded, this);
		this.dataSource.on("beforeload", this.onDataSourceBeforeLoad, this);
		this.dataSource.on("loaded", this.onDataSourceLoaded, this);
		this.dataSource.on("loadexception", this.onDataSourceLoadException, this);
		this.dataSource.on("beforeloadrow", this.onDataSourceBeforeLoadRow, this);
		this.dataSource.on("rowloaded", this.onDataSourceRowLoaded, this);
		this.dataSource.on("rowloadexception", this.onDataSourceLoadException, this);
		this.dataSource.on("structureupdated", this.onDataSourceStructureUpdated, this);
		this.dataSource.on("quickviewcolumnsupdated", this.onDataSourceQuickViewColumnsUpdated, this);
		this.dataSource.on("structureupdateexception", this.onDataSourceStructureUpdateException, this);
		this.dataSource.on("inserted", this.onDataSourceRowInserted, this);
		this.dataSource.on("saved", this.onDataSourceSaved, this);
		this.dataSource.on("saveexception", this.onDataSourceSaveException, this);
		this.dataSource.on("removed", this.onDataSourceRemoved, this);
		this.dataSource.on("canceled", this.onDataSourceCancel, this);
		this.dataSource.on("rowmoved", this.onDataSourceRowMoved, this);
		this.dataSource.on("columnmoved", this.onDataSourceColumnMoved, this);
		this.dataSource.on("columnsremoved", this.onDataSourceColumnsRemoved, this);
		this.dataSource.on("activerowchanged", this.onDataSourceActiveRowChanged, this);
		this.dataSource.on("selectionchanged", this.onDataSourceSelectionChanged, this);
	},

	initDragAndDrop: function () {
		if (this.isDropEnabled() && !this.dropZone) {
			this.dropZone = new Ext.treegrid.TreeDropZone(this, this.dropConfig || {
				ddGroup: this.ddGroup || "TreeDD", appendOnly: this.ddAppendOnly === true,
				enableInnerDragDrop: this.enableInnerDragDrop, dragDropMode: this.dragDropMode
			});
		}
		if (this.isDragEnabled() && !this.dragZone) {
			this.dragZone = new Ext.treegrid.TreeDragZone(this, this.dragConfig || {
				ddGroup: this.ddGroup || "TreeDD",
				scroll: this.ddScroll
			});
		}
	},

	isDropEnabled: function () {
		return this.enableDragDrop || this.enableDrop;
	},

	isDragEnabled: function () {
		return this.enableDragDrop || this.enableDrag;
	},

	isVirtual: function () {
		return Ext.isEmpty(this.dataSource) || Ext.isEmpty(this.dataSource.schemaUId);
	},

	onDataSourceStructureLoaded: function (dataSource, cfg) {
		if (this.initialized) {
			this.updateColumns(true);
			this.initializeQuickFilter();
			this.initializePagingToolbar();
			if (cfg && cfg.attribute && cfg.attribute.callback) {
				cfg.attribute.callback();
			}
		} else {
			this.columnModel = new Ext.treegrid.ColumnModel({
				columns: dataSource.structure.columns
			});
			if (this.rendered) {
				this.initialize();
				if (this.isSummaryVisible) {
					this.view.clearSummary();
					var summaryPlugin = this.getSummaryPlugin();
					summaryPlugin.initEvents();
				}
			}
		}
	},

	initializeQuickFilter: function () {
		if (this.bottomToolbar) {
			var quickFilter = this.bottomToolbar.items.get("quickFilter");
			if (!quickFilter && this.quickFilterVisible && !this.isVirtual()) {
				quickFilter = new Terrasoft.QuickFilter(this);
				this.bottomToolbar.addItem(quickFilter, "quickFilter", 0);
			}
			if (quickFilter) {
				quickFilter.clientClear();
				quickFilter.initializeDataSourceFilters();
				quickFilter.actualize();
			}
		}
	},

	initializePagingToolbar: function () {
		if (this.bottomToolbar) {
			var pagingToolbar = this.bottomToolbar.items.get("pagingToolbar");
			if (pagingToolbar) {
				pagingToolbar.clear();
				this.setPagingToolbarItems();
			}
		}
	},

	initPagingToolbarContextMenu: function() {
		if (this.bottomToolbar !== false) {
			var treegrid = this;
			this.tbmenu = new Ext.menu.Menu({ id: treegrid.id + "-tbctx" });
			var treeGridStringList = Ext.StringList('WC.TreeGrid');
			if (!treegrid.isVirtual()) {
				if (treegrid.enableColumnHide !== false) {
					this.tbmenu.add(
						{ id: "setcolumns", caption: treeGridStringList.getValue('ColumnsMenu.SetColumns') },
						{ id: "setquickviewcolumns", caption: treeGridStringList.getValue('ContextMenu.SetQuickViewColumns') },
						{ id: "selectall", caption: treeGridStringList.getValue('ContextMenu.SelectAll') }
					);
				}
			}
			if (treegrid.showAutoWidthMenu) {
				this.tbmenu.add('-', { id: "autowidth", caption: treeGridStringList.getValue('ColumnsMenu.Autowidth'), checked: treegrid.isColumnAutowidth });
			}
			if (treegrid.showMultiLineMenu) {
				this.tbmenu.add(null , { id: "multiline", caption: treeGridStringList.getValue('ColumnsMenu.Multiline'), checked: treegrid.isMultilineMode });
			}
			if (!treegrid.isVirtual() && treegrid.showSummariesMenu) {
				this.tbmenu.add(null, { id: "summary", caption: treeGridStringList.getValue('ColumnsMenu.Summaries'), checked: treegrid.isSummaryVisible });
			}
			this.tbmenu.on("beforeshow", this.beforeTbMenuShow, this);
			this.tbmenu.on("itemclick", this.handleTbMenuClick, this);
		}
	},

	handleTbMenuClick: function(item) {
		switch (item.id) {
			case "setcolumns":
				this.view.handleSetColumnsMenuClick();
				break;
			case "setquickviewcolumns":
				this.handleSetQuickViewColumnsMenuClick();
				break;
			case "selectall":
				this.selModel.selectAllVisibleNodes();
				break;
			case "summary":
				this.view.handleSummaryMenuClick(item);
				break;
			case "autowidth":
				this.view.handleAutowidthMenuClick(item);
				break;
			case "multiline":
				this.view.handleMultilineMenuClick(item);
				break;
		}
		return true;
	},

	beforeTbMenuShow: function() {
		var menu = this.tbmenu;
		this.setMenuItemChekedValue(menu, "summary", this.isSummaryVisible);
		this.setMenuItemChekedValue(menu, "multiline", this.isMultilineMode);
		this.setMenuItemChekedValue(menu, "autowidth", this.isColumnAutowidth);
	},

	setPagingToolbarItems: function () {
		if (this.bottomToolbar) {
			var pagingToolbar = this.bottomToolbar.items.get("pagingToolbar");
			if (!pagingToolbar) {
				return;
			}
			var refresh = new Terrasoft.ToolButton({
				handler: this.onRefreshPage.createDelegate(this, [true]),
				cls: "x-toolbutton-refresh"
			});
			pagingToolbar.addItem(refresh, "refresh");
			if (!this.isVirtual()) {
				var summary = new Terrasoft.ToolButton({
					enableToggle: true,
					pressed: this.isSummaryVisible,
					handler: this.onViewSummary.createDelegate(this),
					cls: "x-toolbutton-summary"
				});
				pagingToolbar.addItem(summary, "summary");
				var exportData = new Terrasoft.ToolButton({
					handler: this.onExportData.createDelegate(this),
					cls: "x-toolbutton-exportdata",
					enabled: this.allowExportData
				});
				pagingToolbar.addItem(exportData, "exportdata");
				pagingToolbar.addItem(new Terrasoft.Tools.Separator(), "pagingSeparator");
				var firstPage = new Terrasoft.ToolButton({
					handler: this.onFirstPage.createDelegate(this),
					cls: "x-toolbutton-firstPage",
					enabled: false
				});
				pagingToolbar.addItem(firstPage, "firstPage");
				var previousPage = new Terrasoft.ToolButton({
					handler: this.onPrevPage.createDelegate(this),
					cls: "x-toolbutton-previousPage",
					enabled: false
				});
				pagingToolbar.addItem(previousPage, "previousPage");
				var pagingEdit = pagingToolbar.createPagingEdit();
				pagingToolbar.addItem(pagingEdit, "pagingEdit");
				pagingToolbar.setPage(1);
				var nextPage = new Terrasoft.ToolButton({
					handler: this.onNextPage.createDelegate(this),
					cls: "x-toolbutton-nextPage",
					enabled: false
				});
				pagingToolbar.addItem(nextPage, "nextPage");
			}
			var contextMenu = new Terrasoft.ToolButton({
				handler: this.onContextMenu.createDelegate(this),
				cls: "x-toolbutton-contextMenu"
			});
			pagingToolbar.addItem(contextMenu, "contextmenu", 3);
			this.initPagingToolbarContextMenu();
			if (this.designMode || this.enabled === false) {
			this.bottomToolbar.disable();
			}
		}
		
	},

	createRootNode: function () {
		this.nodeHash = {};
		this.root = new Ext.treegrid.AsyncTreeNode({ id: 'Root' });
		this.setRootNode(this.root);
		return this.root;
	},

	onDataSourceLoaded: function (dataSource, rows, cfg) {
		if (!this.rendered) {
			this.deferredData = {
				dataSource: dataSource,
				rows: rows,
				cfg: cfg
			};
			return;
		}
		var node, callback;
		if (cfg && cfg.attribute) {
			var attribute = cfg.attribute;
			node = attribute.node;
			callback = attribute.callback;
		} else {
			node = this.root;
			if (node.rendered && (cfg.add === true)) {
				callback = node.dataLoadingComplete.createDelegate(node);
			} else {
				callback = node.loadPageComplete.createDelegate(node);
			}
		}
		var lastChildNode = node.lastChild;
		if (lastChildNode && lastChildNode.isPaging) {
			node.previousPagingNode = node.lastChild;
		}
		node.hasNextPage = cfg ? cfg.hasNextPage : false;
		if (rows.length > 0) {
			node.addLoadedRecords(rows, dataSource, cfg);
		} else {
			node.leaf = true;
		}
		if (typeof callback == "function") {
			callback(this, node);
		}
	},

	onDataSourceRowLoaded: function (dataSource, data, cfg) {
		var node, callback;
		if (cfg && cfg.attribute) {
			callback = cfg.attribute.callback;
		}
		var row = data[0];
		var primaryColumnName = dataSource.structure.primaryColumnName;
		var rowId = row[primaryColumnName];
		node = this.getNodeById(rowId);
		if (node) {
			if (node.ui.rendered) {
				node.ui.rerenderData();
				var selModel = this.getSelectionModel();
				if (selModel.activeCellIndex != null) {
					selModel.focusCell(selModel.activeCellIndex);
				}
				if (node.isSelected) {
					selModel.updateSelData(node.id);
				}
			}
			this.hideLoadMask(node);
		} else {
			this.root.addLoadedRecords(data, dataSource, cfg);
			this.root.dataLoadingComplete();
			this.selectNodeById(rowId);
			node = this.getNodeById(rowId);
		}
		if (typeof callback == "function") {
			callback(this, node);
		}
		this.markSummaryAsWrong();
		if (node.ui.isQuickViewVisible) {
			this.quickView.show(node.ui);
		}
	},

	onDataSourceStructureUpdated: function (dataSource, cfg) {
		if (cfg && cfg.attribute && cfg.attribute.callback) {
			cfg.attribute.callback();
		}
		this.hideLoadMask(this.root);
	},

	onDataSourceQuickViewColumnsUpdated: function (dataSource) {
		if (this.hasQuickView()) {
			this.updateOpenedQuickViews();
		}
	},

	onDataSourceActiveRowChanged: function(dataSource, rowId) {
		var selModel = this.selModel;
		if (selModel.treegrid && selModel.treegrid.rendered &&
				selModel.activeNode && selModel.activeNode.id != rowId) {
			this.setActiveNodeById(rowId);
		}
	},

	onDataSourceSelectionChanged: function (dataSource, senderKey) {
		if (senderKey != this.id) {
			this.selModel.clearSelections(true);
			if (dataSource.activeRow) {
				var nodeId = dataSource.activeRow.getPrimaryColumnValue();
				var node = this.getNodeById(nodeId);
				if (node != this.selModel.activeNode) {
					this.selModel.activeNode = node;
				}
			}
			var ids = this.dataSource.selData;
			this.selectNodes(ids, true, true);
		}
	},

	onDataSourceColumnMoved: function (columnUId, position, cfg) {
		var columnModel = this.columnModel;
		var columns = columnModel.config;
		var column = columnModel.getColumnByUId(columnUId);
		var index = columns.indexOf(column);
		var oldPosition = columnModel.getColumnPosition(index);
		var newPosition = columnModel.getColumnPosition(position);
		columns.splice(index, 1);
		columns.splice(position, 0, column);
		this.view.onColumnMove(columnModel, oldPosition, newPosition);
		if (cfg && cfg.attribute && cfg.attribute.callback) {
			cfg.attribute.callback();
		}
		this.hideLoadMask(this.root);
		this.dataSource.setColumnsProfileData();
	},

	onDataSourceColumnsRemoved: function (removedColumns, cfg) {
		if (cfg && cfg.attribute && cfg.attribute.callback) {
			cfg.attribute.callback();
		}
	},

	onDataSourceStructureUpdateException: function (dataSource, responseText, cfgId) {
		this.hideLoadMask(this.root);
	},

	onDataSourceSaved: function (dataSource, row, cfg) {
		this.markSummaryAsWrong();
	},

	onDataSourceSaveException: function (dataSource, responseText) {
		var nodeId = dataSource.activeRow.getPrimaryColumnValue();
		var node = this.getNodeById(nodeId);
		node.parentNode.removeChild(node);
		this.view.processRows();
		this.view.updateScroll();
	},

	onParentContainerShow: function(el) {
		el.un('show', this.onParentContainerShow, this);
		if (this.deferredData && this.isVisible()) {
			this.applyDeferredData();
		}
	},
	
	insert: function (index, item) {
		if (item instanceof Ext.menu.Item) {
			item.rendered = false;
			item.parentMenu = this.contextMenu;
			if (index == -1 && this.menuConfig) {
				index = this.menuConfig.length;
			}
			return this.contextMenu.insert(index, item);
		}
	},
	
	add: function(item) {
		if (item instanceof Ext.menu.Item) {
			item.rendered = false;
			item.parentMenu = this.contextMenu;
			return this.contextMenu.add(item);
		}
	},

	remove: function(item, leave) {
		if (item instanceof Ext.menu.Item) {
			if (!leave) {
				this.contextMenu.destroy(item, leave);
			} else if (item.rendered) {
				this.contextMenu.remove(item, leave);
			}
		}
	},
	
	applyDeferredData: function() {
		var data = this.deferredData;
		var dataSource = data.dataSource;
		this.onDataSourceLoaded(dataSource, data.rows, data.cfg);
		if (this.selModel.activeNode == null && dataSource.activeRow) {
			this.onDataSourceSelectionChanged(dataSource.selData, "");
		}
		delete this.deferredData;
	},

	getTreeEl: function () {
		return this.container;
	},

	getTreeBodyEl: function () {
		return this.tbar ? this.getTreeEl().dom.childNodes[1] : this.getTreeEl().dom.firstChild;
	},

	proxyNodeEvent: function (ename, a1, a2, a3, a4, a5, a6) {
		if (ename == 'collapse' || ename == 'expand' || ename == 'beforecollapse' ||
			ename == 'beforeexpand' || ename == 'move' || ename == 'beforemove' || ename == 'dblclick') {
			ename = ename + 'node';
		}
		return this.fireEvent(ename, a1, a2, a3, a4, a5, a6);
	},

	setRootNode: function (node) {
		this.root = node;
		node.treegrid = this;
		node.isRoot = true;
		this.registerNode(node);
		node.ui = new Ext.treegrid.RootTreeNodeUI(node);
		return node;
	},

	getNodeById: function (id) {
		if (this.nodeHash) {
			return this.nodeHash[id];
		} else {
			return null;
		}
	},

	getNodeByRowIndex: function (rowIndex) {
		return this.nodeHash[Ext.get(this.view.getRows()[rowIndex]).getAttributeNS('ext', 'tree-node-id')];
	},

	registerNode: function (node) {
		this.nodeHash[node.id] = node;
	},

	unregisterNode: function (node) {
		delete this.nodeHash[node.id];
	},

	getRootNode: function () {
		return this.root;
	},

	restrictExpand: function (node) {
		var p = node.parentNode;
		if (p) {
			if (p.expandedChild && p.expandedChild.parentNode == p) {
				p.expandedChild.collapse();
			}
			p.expandedChild = node;
		}
	},

	getChecked: function (a, startNode) {
		startNode = startNode || this.root;
		var r = [];
		var f = function () {
			if (this.attributes.checked) {
				r.push(!a ? this : (a == 'id' ? this.id : this.attributes[a]));
			}
		};
		startNode.cascade(f);
		return r;
	},

	getEl: function () {
		return this.el;
	},

	expandAll: function () {
		this.root.expand(true);
	},

	collapseAll: function () {
		this.root.collapse(true);
	},

	expandPath: function (path, attr, callback) {
		attr = attr || "id";
		var keys = path.split(this.pathSeparator);
		var curNode = this.root;
		if (curNode.attributes[attr] != keys[1]) {
			if (callback) {
				callback(false, null);
			}
			return;
		}
		var index = 1;
		var f = function () {
			if (++index == keys.length) {
				if (callback) {
					callback(true, curNode);
				}
				return;
			}
			var c = curNode.findChild(attr, keys[index]);
			if (!c) {
				if (callback) {
					callback(false, curNode);
				}
				return;
			}
			curNode = c;
			c.expand(false, false, f);
		};
		curNode.expand(false, false, f);
	},

	selectPath: function (path, attr, callback) {
		attr = attr || "id";
		var keys = path.split(this.pathSeparator);
		var v = keys.pop();
		if (keys.length > 0) {
			var f = function (success, node) {
				if (success && node) {
					var n = node.findChild(attr, v);
					if (n) {
						n.select();
						if (callback) {
							callback(true, n);
						}
					} else if (callback) {
						callback(false, n);
					}
				} else {
					if (callback) {
						callback(false, n);
					}
				}
			};
			this.expandPath(keys.join(this.pathSeparator), attr, f);
		} else {
			this.root.select();
			if (callback) {
				callback(true, this.root);
			}
		}
	},

	getColumns: function () {
		var columnModel = this.getColumnModel();
		return columnModel.config;
	},

	isTreeMode: function () {
		return this.dataSource && !Ext.isEmpty(this.dataSource.getHierarchicalColumnName());
	},

	addSorting: function (column, direction, multiSorting) {
		var colConfig = new Object;
		var clearConfig = this.getClearSortingConfig(column, multiSorting);
		if (clearConfig) {
			colConfig = clearConfig.colConfig;
		}		
		if (multiSorting && clearConfig.isUpdateColumnsSortingPositions)
			this.updateColumnsSortingPositions(colConfig, column, multiSorting);
		var clearCurrentColumnSorting = clearConfig.clearCurrentColumnSorting;
		if (!multiSorting || clearCurrentColumnSorting !== true) {
			this.addColumnSorting(colConfig, column, direction, multiSorting);
		}
		this.showLoadMask(this.root);
		this.clear(true);
		this.dataSource.updateStructure({
			attribute: {
				callback: this.view.updateHeaders.createDelegate(this.view)
			},
			columns: colConfig
		}, true);
	},

	addColumnSorting: function (colConfig, column, direction, multiSorting, orderPosition) {
		var position = multiSorting ? orderPosition || column.orderPosition : 1;
		if (!position) {
			position = this.getMaxSortingPosition() + 1;
		}
		colConfig[column.name] = new Object();
		colConfig[column.name].orderPosition = position;
		colConfig[column.name].orderDirection = direction;
	},

	updateColumnsSortingPositions: function (colConfig, pColumn, multiSorting) {	
		var columns = this.getColumns();
		for (var i = 0, column, orderDirection, orderPosition, count = columns.length; i < count; i++) {
			column = columns[i];
			orderDirection = column.orderDirection;
			orderPosition = column.orderPosition;
			if (orderDirection && orderPosition && column.metaPath != pColumn.metaPath && 
				orderDirection != "None" && orderPosition>pColumn.orderPosition) {
				this.addColumnSorting(colConfig, column, orderDirection, multiSorting, orderPosition - 1);
			}
		}		
	},

	getClearSortingConfig: function (pColumn, multiSorting) {
		var clearSortClickCount = 3;
		var columns = this.getColumns();
		var colConfig = new Object();
		var clearCurrentColumnSorting = false;
		var addColConfig = false;
		var isUpdateColumnsSortingPositions = false;
		for (var i = 0, column, count = columns.length; i < count; i++) {
			column = columns[i];
			if (multiSorting) {
				if (column.metaPath == pColumn.metaPath && column.orderDirection != "None") {
					var clickCount = this.view.columnSortingHash[column.metaPath];
					if (clickCount && clickCount === clearSortClickCount) {
						addColConfig = clearCurrentColumnSorting = true;
						this.view.columnSortingHash[column.metaPath] = null;
					}
				}
			} else {
				addColConfig = column.orderDirection != "None";
			}
			if (addColConfig) {
				colConfig[column.name] = new Object();
				colConfig[column.name].orderPosition = 0;
				colConfig[column.name].orderDirection = "None";
				isUpdateColumnsSortingPositions = true;
			}
			addColConfig = false;			
		}
		return {colConfig:colConfig, clearCurrentColumnSorting:clearCurrentColumnSorting, isUpdateColumnsSortingPositions:isUpdateColumnsSortingPositions};
	},

	getMaxSortingPosition: function () {
		var columns = this.getColumns();
		var position = 0;
		for (var i = 0, column, count = columns.length; i < count; i++) {
			column = columns[i];
			if (column.orderPosition > position && column.orderDirection != "None") {
				position = column.orderPosition;
			}
		}
		return position;
	},

	getSortingColumns: function() {
		var columns = this.getColumns();
		var sortingColumns = [];
		for (var i = 0, column, l = columns.length; i < l; i++) {
			column = columns[i];
			if (column.orderDirection != "None") {
				sortingColumns.push(column);
			}
		}
		var sortFunction = function(a, b) {
			return (a.orderPosition - b.orderPosition);
		};
		sortingColumns.sort(sortFunction);
		return sortingColumns;
	},

	initEvents: function () {
		Ext.Panel.prototype.initEvents.call(this);
		this.initEditing();
		if (this.containerScroll) {
			Ext.dd.ScrollManager.register(this.body);
		}
	},

	doNextPage: function (doRefreshSummaries) {
		var rootNode = this.root;
		if (!rootNode.hasNextPage) {
			return;
		}
		var pageableRowId = rootNode.lastChild.id;
		var loadingParameters = {
			pageableRowId: pageableRowId,
			attribute: {
				node: rootNode,
				callback: rootNode.loadPageComplete.createDelegate(rootNode)
			}
		};
		var treegrid = rootNode.treegrid;
		if (treegrid.isTreeMode()) {
			var dataSource = treegrid.dataSource;
			var hierarchicalColumnName = dataSource.getHierarchicalColumnName();
			if (hierarchicalColumnName) {
				loadingParameters.filteredColumnName = hierarchicalColumnName;
				loadingParameters.filterValue = rootNode.getParentId(pageableRowId);
			}
		}
		this.clear(true, true);
		this.dataSource.loadNextPage(loadingParameters);
	},

	doPrevPage: function () {
		var rootNode = this.root;
		var pageableRow = rootNode.firstChild;
		if (!pageableRow) {
			return;
		}
		var pageableRowId = rootNode.firstChild.id;
		this.clear(true, true);
		this.dataSource.loadPreviousPage({
			pageableRowId: pageableRowId,
			attribute: {
				node: rootNode,
				callback: rootNode.loadPageComplete.createDelegate(rootNode)
			}
		});
	},

	doFirstPage: function (doRefreshSummaries) {
		var rootNode = this.root;
		this.clear(true, true);
		this.dataSource.loadFirstPage({
			attribute: {
				node: rootNode,
				callback: rootNode.loadPageComplete.createDelegate(rootNode)
			}
		});
		if (doRefreshSummaries) {
			this.refreshSummaries();
		}
	},

	setFirstPage: function () {
		this.onFirstPage();
	},

	refreshSummaries: function () {
		if (this.isSummaryVisible) {
			this.view.renderSummary();
		}
	},

	doRefreshPage: function (doRefreshSummaries) {
		var rootNode = this.root;
		var pageableRowId = rootNode.firstChild ? rootNode.firstChild.id : null;
		this.clear(false, true);
		if (this.columnModel.config.length > 0) {
			this.dataSource.refreshPage({
				pageableRowId: pageableRowId,
				attribute: {
					node: rootNode,
					callback: rootNode.loadPageComplete.createDelegate(rootNode)
				}
			});
			if (doRefreshSummaries) {
				this.refreshSummaries();
			} else {
				this.markSummaryAsWrong();
			}
		}
	},

	refreshData: function () {
		if (this.rendered) {
			this.setFirstPage();
			this.markSummaryAsWrong();
		}
	},

	appendChildNode: function (n, parentNode, expand, point, targetNode) {
		switch (point) {
			case "Append":
				parentNode.appendChild(n);
				break;
			case "Above":
				parentNode.insertBefore(n, targetNode);
				break;
			case "Below":
				parentNode.insertBefore(n, targetNode.nextSibling);
				break;
			default:
				parentNode.appendChild(n);
		}
		var treegrid = n.getTreeGrid();
		if (parentNode.expanded || parentNode.isRoot) {
			n.render();
			if (n.isLast() && n.previousSibling) {
				n.previousSibling.ui.repaintChildIndent();
			}
			treegrid.view.processRows();
		} else {
			treegrid.registerNode(n);
			if (parentNode.childNodes.length == 1) {
				parentNode.ui.updateExpandIcon();
			}
			if (expand && parentNode.rendered) {
				parentNode.expand();
			}
		}
		parentNode.endUpdate();
		var treegrid = parentNode.getTreeGrid();
		var view = treegrid.view;
		view.updateScroll();
		return n;
	},

	createNode: function (attr, cfg) {
		if (this.baseAttrs) {
			Ext.applyIf(attr, this.baseAttrs);
		}
		attr.uiProvider = Terrasoft.ColumnNodeUI;
		var node = attr.nodeType ? new Terrasoft.TreeGrid.nodeTypes[attr.nodeType](attr) : (attr.leaf ? new Ext.treegrid.TreeNode(attr) : new Ext.treegrid.AsyncTreeNode(attr));
		node.initialConfig = cfg || {};
		Ext.apply(node, node.initialConfig);
		return node;
	},

	removeNodeById: function (nodeId) {
		if (!this.rendered) {
			return;
		}
		var node = this.getNodeById(nodeId);
		node.parentNode.removeChild(node);
	},

	removeNodeChildren: function (nodeId) {
		if (!this.rendered) {
			return;
		}
		var node = this.getNodeById(nodeId);
		node.removeChildren();
	},

	moveNodeToPosition: function (nodeId, parentId, position) {
		var n = this.getNodeById(nodeId);
		var p = this.getNodeById(parentId);
		if ((n.parentNode == p) && (p.childNodes[position] == n)) {
			return;
		}
		n.parentNode.removeChild(n, false);
		p.beginUpdate();
		p.insertBefore(n, p.childNodes[position]);
		p.endUpdate();
		this.view.processRows();
		p.ui.repaintChildIndent();
	},

	moveNode: function (nodeId, step) {
		var n = this.getNodeById(nodeId);
		if (!n) {
			return;
		}
		var p = n.parentNode;
		if (!p) {
			return;
		}
		var position = p.childNodes.indexOf(n) + step;
		if (position < 0 || position > p.childNodes.length) {
			return;
		}
		n.parentNode.removeChild(n, false);
		p.beginUpdate();
		p.insertBefore(n, p.childNodes[position]);
		p.endUpdate();
		n.rerender(true);
		this.selModel.select(n);
	},

	updateNode: function (node, nodeConfig) {
		var ns = node.nextSibling;
		var p = node.parentNode;
		this.suspendEvents();
		try {
			var isSelected = node.isSelected();
			if (isSelected) {
				node.unselect();
			}
			Ext.apply(node, nodeConfig.config);
			Ext.apply(node.attributes, nodeConfig.values);
			node.ui.rerenderData();
			if (isSelected) {
				node.select();
			}
		} finally {
			this.resumeEvents();
		}
	},

	repaintChildNodes: function (children) {
		for (var i = 0, len = children.length; i < len; i++) {
			children[i].rendered = false;
		}
		var child;
		for (var i = 0, len = children.length; i < len; i++) {
			child = children[i];
			child.ui.rerender();
			child.rendered = true;
			if (child.expanded) {
				child.showChildrenContainer();
			}
			child.ui.updateExpandIcon();
			if (child.childNodes.length > 0) {
				this.repaintChildNodes(child.childNodes);
			}
		}
	},

	getNodeByFieldValue: function (fieldName, value) {
		var columnModel = this.getColumnModel();
		if (columnModel.getIndexByName(fieldName) == -1) {
			return null;
		}
		var nodes = this.nodeHash;
		var node;
		var fieldValue;
		for (var nodeId in nodes) {
			node = nodes[nodeId];
			fieldValue = node.attributes[fieldName] || '';
			if (fieldValue == value) {
				return node;
			}
		}
		return null;
	},

	updateNodeById: function (nodeId, nodeConfig) {
		var node = this.getNodeById(nodeId);
		if (!node) {
			return false;
		}
		var cfg = eval("(" + nodeConfig + ")");
		this.updateNode(node, cfg);
		return true;
	},

	updateNodeByFieldValue: function (fieldName, value, nodeConfig) {
		var node = this.getNodeByFieldValue(fieldName, value);
		if (!node) {
			return false;
		}
		var cfg = eval("(" + nodeConfig + ")");
		this.updateNode(node, cfg);
		return true;
	},

	setActiveNodeById: function (nodeId) {
		var node = this.getNodeById(nodeId);
		this.selModel.setActiveNode(node);
	},

	selectNodeById: function (nodeId, suppressEvents, keepSelection) {
		if (!this.rendered) {
			return;
		}
		var node = this.getNodeById(nodeId);
		if (!node) {
			return false;
		}
		if (suppressEvents) {
			this.suspendEvents();
			try {
				this.selModel.select(node, keepSelection, suppressEvents);
			} finally {
				this.resumeEvents();
			}
		} else {
			this.selModel.select(node, keepSelection);
		}
		this.view.scrollTo(node.ui.elNode);
	},

	selectNodes: function (ids, suppressEvents, keepSelection) {
		var selModel = this.selModel;
		for (var i = 0; i < ids.length; i++) {
			var nodeId = ids[i];
			if (!selModel.selMap[nodeId]) {
				this.selectNodeById(nodeId, suppressEvents, keepSelection);
			}
		}
	},

	setColumnVisible: function (columnName, visible) {
		var columnModel = this.getColumnModel();
		var columnIndex = columnModel.getIndexByName(columnName);
		if (columnIndex != -1) {
			columnModel.setVisible(columnIndex, visible);
		}
	},

	setColumnWidth: function (columnName, width) {
		var columnModel = this.getColumnModel();
		var columnIndex = columnModel.getIndexByName(columnName);
		if (columnIndex != -1) {
			columnModel.setColumnWidth(columnIndex, width);
		}
	},

	expandNode: function (nodeId) {
		var node = this.getNodeById(nodeId);
		if (this.isTreeMode() && node) {
			node.expand();
		}
	},

	collapseNode: function (nodeId) {
		var node = this.getNodeById(nodeId);
		if (this.isTreeMode() && node) {
			node.collapse();
		}
	},

	onDestroy: function () {
		if (this.rendered) {
			if (this.isTreeMode()) {
				this.body.removeAllListeners();
				Ext.dd.ScrollManager.unregister(this.body);
				if (this.dropZone) {
					this.dropZone.unreg();
				}
				if (this.dragZone) {
					this.dragZone.unreg();
				}
			}
		}
		if (this.root) {
			this.root.destroy();
		}
		this.nodeHash = null;
		Terrasoft.TreeGrid.superclass.onDestroy.call(this);
	},

	onDataSourceBeforeLoad: function (dataSource, cfg) {
		if (!this.rendered) {
			return;
		}
		var columnModel = this.getColumnModel();
		if (!columnModel) {
			this.onDataSourceStructureLoaded(dataSource);
		}
		var node = (cfg.attribute) ? cfg.attribute.loadNode || cfg.attribute.node : this.root;
		this.showLoadMask(node);
	},

	onDataSourceBeforeLoadRow: function (dataSource, cfg) {
		var node = this.getNodeById(cfg.primaryColumnValue);
		if (node) {
			this.showRowLoadMask(node);
		}
	},

	showLoadMask: function (node) {
		if (node.isRoot) {
			var loadMask = new Ext.LoadMask(Ext.get(this.el));
			node.loadMask = loadMask;
			node.loadMask.show();
		} else {
			node.ui.enableLoadingState(true);
		}
	},

	showRowLoadMask: function (node) {
		loadMask = new Ext.LoadMask(Ext.get(node.ui.wrap), {
			msg: Ext.StringList('WC.Common').getValue('LoadMask.RefreshData'),
			fitToElement: true
		});
		node.loadMask = loadMask;
		node.loadMask.show();
	},

	onDataSourceLoadException: function (dataSource, responseText, cfg) {
		var node = (cfg.attribute) ? cfg.attribute.loadNode || cfg.attribute.node : this.root;
		this.hideLoadMask(node);
	},

	hideLoadMask: function (node) {
		if (node.loadMask) {
			node.loadMask.hide();
			delete node.loadMask;
		} else {
			node.ui.enableLoadingState(false);
		}
	},

	initContextMenu: function () {
		if (this.enableContextMenu && !this.designMode) {
			if (this.contextMenuId) {
				this.contextMenu = eval(this.contextMenuId);
			}
			if (!this.contextMenu) {
				this.contextMenu = new Ext.menu.Menu();
			}
			if (this.menuConfig && this.menuConfig.length > 0) {
				this.contextMenu.createItemsFromConfig(this.menuConfig);
				this.contextMenu.add("-");
			}
			var treeGridStringList = Ext.StringList('WC.TreeGrid');
			if (!this.isVirtual()) {
				this.contextMenu.add({
					id: "goto",
					caption: treeGridStringList.getValue('ContextMenu.GoTo')
				});
				if (!this.hideHeaders) {
					this.contextMenu.add({
						id: "setcolumns",
						caption: treeGridStringList.getValue('ColumnsMenu.SetColumns')
					});
				}
				if (this.quickViewMode != 'None') {
					this.contextMenu.add({
						id: "setquickviewcolumns",
						caption: treeGridStringList.getValue('ContextMenu.SetQuickViewColumns')
					});
				}
			}
			if (this.selModel instanceof Terrasoft.treegrid.MultiRowsSelectionModel) {
				this.contextMenu.add({
					id: "selectall",
					caption: treeGridStringList.getValue('ContextMenu.SelectAll')
				},
					(this.showAutoWidthMenu || this.showMultiLineMenu || this.showSummariesMenu) ? '-' : null);
			}
			if (this.showAutoWidthMenu) {
				this.contextMenu.add({
					id: "autowidth",
					caption: treeGridStringList.getValue('ColumnsMenu.Autowidth'),
					checked: this.isColumnAutowidth
				});
			}
			if (this.showMultiLineMenu) {
				this.contextMenu.add({
					id: "multiline",
					caption: treeGridStringList.getValue('ColumnsMenu.Multiline'),
					checked: this.isMultilineMode
				});
			}
			if (!this.isVirtual()) {
				if (this.showSummariesMenu) {
					this.contextMenu.add({
						id: "summary",
						caption: treeGridStringList.getValue('ColumnsMenu.Summaries'),
						checked: this.isSummaryVisible
					});
				}
			}
			this.handleContextMenu = true;
			this.getEl().on('contextmenu', this.onContextMenuEvent, this);
			this.contextMenu.on("itemclick", this.handleContextMenuClick, this);
			this.contextMenu.on("beforeshow", this.beforeContextMenuShow, this);
			this.contextMenu.on("hide", this.handleContextMenuHide, this);
		}
	},

	onContextMenuEvent: function (e, t) {
		var isClickOnSelection = this.getIsClickOnSelection(t);
		if (isClickOnSelection) {
			return;
		} else {
			Terrasoft.TreeGrid.superclass.onContextMenuEvent.call(this, e, t);
		}
	},

	getIsClickOnSelection: function (target) {
		var selectedText = this.getSelectedText();
		var targetText = Ext.isGecko ? target.textContent : target.innerText;
		return (!Ext.isEmpty(selectedText) && (targetText.indexOf(selectedText) != -1));
	},

	getSelectedText: function (target) {
		if (Ext.isIE) {
			var selection = document.selection;
			var range = selection.createRange();
			var html = range.text;
		} else {
			var selection = window.getSelection();
			var html = selection.toString();
		}
		return html;
	},

	beforeContextMenuShow: function (menu) {
		this.el.addClass("x-treegrid-context-menu-open");
		this.setMenuItemChekedValue(menu, "summary", this.isSummaryVisible);
		this.setMenuItemChekedValue(menu, "multiline", this.isMultilineMode);
		this.setMenuItemChekedValue(menu, "autowidth", this.isColumnAutowidth);
		this.prepareGotoMenuItem(menu);
		var isTreeMode = this.isTreeMode();
		this.setMenuItemVisibleValue(menu, "selectall", !isTreeMode);
	},

	handleContextMenuHide: function () {
		this.el.removeClass("x-treegrid-context-menu-open");
		this.focus();
	},

	setMenuItemChekedValue: function (menu, itemId, value) {
		var item = menu.items.map[itemId];
		if (item) {
			item.setChecked(value);
		}
	},

	setMenuItemEnabled: function (menu, itemId, enabled) {
		var item = menu.items.map[itemId];
		if (item) {
			item.setEnabled(enabled);
		}
	},

	setMenuItemVisibleValue: function (menu, itemId, visible) {
		var item = menu.items.map[itemId];
		if (item) {
			item.setVisible(visible);
		}
	},

	prepareGotoMenuItem: function (menu) {
		var gotoMenuItem = menu.items.map["goto"];
		var modulesList = window.modules;
		if (!gotoMenuItem || !modulesList || !this.selModel.activeNode) {
			if (gotoMenuItem) {
				gotoMenuItem.setVisible(false);
			}
			return;
		}
		if (gotoMenuItem.menu) {
			gotoMenuItem.menu.removeAll();
		} else {
			var gotoSubMenu = new Ext.menu.Menu();
			gotoSubMenu.owner = gotoMenuItem;
			gotoMenuItem.menu = gotoSubMenu;
		}
		var columns = this.getColumns();
		var activeRowId = this.selModel.activeNode.id;
		var activeRow = this.dataSource.getRow(activeRowId);
		for (var i = 0; i < columns.length; i++) {
			var column = columns[i];
			var refSchemaUId, refSchemaCaption;
			if (column.isLookup) {
				refSchemaUId = column.refSchemaUId;
			} else {
				continue;
			}
			var modulePageSchemaUId = modulesList[refSchemaUId];
			var refItemUId = activeRow.getColumnValue(column.valueColumnName);
			if (modulePageSchemaUId && refItemUId && !this.isColumnAccessDenied(column, activeRow.columns)) {
				var refItem = activeRow.getColumnValue(column.displayColumnName);
				gotoMenuItem.menu.add({
					caption: column.caption,
					modulePageSchemaUId: modulePageSchemaUId,
					primaryColumnValue: refItemUId,
					primaryDisplayValue: refItem
				});
			}
		}
		var sortFunction = function(a, b) {
			return (a.caption < b.caption ? -1 : 1);
		};
		gotoMenuItem.menu.items.sort("ASC", sortFunction);
		gotoMenuItem.setVisible(gotoMenuItem.menu.items.length > 0);
	},

	handleContextMenuClick: function (item) {
		if (item.parentMenu && item.parentMenu.owner && item.parentMenu.owner.id == "goto") {
			this.gotoModuleByMenuItem(item);
		} else {
			switch (item.id) {
				case "setcolumns":
					this.view.handleSetColumnsMenuClick();
					break;
				case "setquickviewcolumns":
					this.handleSetQuickViewColumnsMenuClick();
					break;
				case "selectall":
					this.selModel.selectAllVisibleNodes();
					break;
				case "summary":
					this.view.handleSummaryMenuClick(item);
					break;
				case "autowidth":
					this.view.handleAutowidthMenuClick(item);
					break;
				case "multiline":
					this.view.handleMultilineMenuClick(item);
					break;
			}
		}
	},

	gotoModuleByMenuItem: function (item) {
		var urlTemplate = "{0}?Id={1}&moduleId={2}&pcv={3}&pdv={4}";
		var path = window.location.pathname;
		var mainPageId = this.getMainPageIdFromURL();
		var url = String.format(urlTemplate, path, encodeURIComponent(mainPageId),
			encodeURIComponent(item.modulePageSchemaUId), encodeURIComponent(item.primaryColumnValue),
			encodeURIComponent(item.primaryDisplayValue));
		window.location = url;
	},

	getMainPageIdFromURL: function () {
		var id = "";
		var parameterString = window.location.search;
		if (!Ext.isEmpty(parameterString)) {
			var params = parameterString.substr(1, parameterString.length);
			var paramsArray = params.split("&");
			for (var i = 0; i < paramsArray.length; i++) {
				var item = paramsArray[i].split("=");
				if (item[0] == "Id") {
					return item[1];
				}
			}
		}
		return id;
	},

	handleSetQuickViewColumnsMenuClick: function () {
		this.fireEvent("setquickviewcolumns");
	},

	deleteSelectedNodes: function () {
		var selectionModel = this.getSelectionModel();
		var selMap = selectionModel.selMap;
		var activeNode = selectionModel.activeNode;
		var wasDelete = false;
		for (var nodeId in selMap) {
			if (nodeId != activeNode.id) {
				selMap[nodeId].remove();
				wasDelete = true;
			}
		}
		if (activeNode) {
			activeNode.remove();
			wasDelete = true;
		}
		if (wasDelete) {
			this.view.processRows();
		}
		return wasDelete;
	},

	deleteNodesByRowValues: function (fieldName, values) {
		var columnModel = this.getColumnModel();
		var wasDelete = false;
		if (columnModel.getIndexByName(fieldName) == -1) {
			return wasDelete;
		}
		var selectionModel = this.getSelectionModel();
		var activeNode = selectionModel.activeNode;
		var nodes = this.nodeHash;
		var selectedNodeDeleting = false;
		var node;
		var fieldValue;
		for (var nodeId in nodes) {
			node = nodes[nodeId];
			fieldValue = node.attributes[fieldName] || '';
			if (values.indexOf(fieldValue) != -1) {
				if (nodeId != activeNode.id) {
					nodes[nodeId].remove();
					wasDelete = true;
				} else {
					selectedNodeDeleting = true;
				}
			}
		}
		if (selectedNodeDeleting) {
			if (!selectionModel.selectNext()) {
				selectionModel.selectPrevious();
			}
			activeNode.remove();
			wasDelete = true;
		}
		if (wasDelete) {
			selectionModel.clearSelNodes();
			this.view.processRows();
		}
		return wasDelete;
	},

	selectFirstRow: function () {
		var rootNode = this.getRootNode();
		var firstChild = rootNode.firstChild;
		var selModel = this.getSelectionModel();
		if (firstChild) {
			this.suspendEvents();
			selModel.select(firstChild);
			selModel.setActiveNode(firstChild);
			this.resumeEvents();
		}
	},

	sendValueLinkNotification: function (valueLinkId, node) {
		valueLinkId = Ext.util.JSON.encode(valueLinkId);
		var nodeId = Ext.util.JSON.encode(node.id);
		this.fireEvent("linkclick", valueLinkId, nodeId);
	},

	sendCellIconClickNotification: function (cellIconId, node) {
		cellIconId = Ext.util.JSON.encode(cellIconId);
		var nodeId = Ext.util.JSON.encode(node.id);
		this.fireEvent("celliconclick", cellIconId, nodeId);
	},

	getSummaryPlugin: function () {
		if (this.plugins) {
			return this.plugins["summary"];
		} else {
			return null;
		}
	},

	showSummary: function (visible) {
		this.view.showSummary(visible);
	},

	enableColumnAutowidth: function (enabled) {
		this.view.enableColumnAutowidth(enabled);
	},

	enableMultiline: function (enabled) {
		this.view.enableMultiline(enabled);
	},

	findNodeById: function (id) {
		var result;
		var node = this.getNodeById(id);
		if (node) {
			result = node.attributes;
		}
		result = Ext.util.JSON.encode(result, 2);
		this.fireEvent("findnodebyidcomplete", result);
	},

	refreshNode: function (node) {
		this.dataSource.loadRow({
			primaryColumnValue: node.id
		});
		if (node.ui.isQuickViewVisible) {
			this.quickView.show(node.ui);
		}
	},

	refreshSelectedNode: function () {
		var node = this.selModel.activeNode;
		this.refreshNode(node);
	},

	editSelectedCell: function (enableByClick) {
		var selModel = this.getSelectionModel();
		var selNode = selModel.activeNode;
		var colIndex = selModel.activeCellIndex;
		var colModel = this.getColumnModel();
		var colName = colModel.getColumnName(colIndex);
		this.startEditing(selNode, colName, enableByClick);
	},

	insertRow: function (editAfterInsert) {
		var selModel = this.getSelectionModel();
		var parentNode = selModel.activeNode.parentNode;
		var targetNode = parentNode.lastChild;
		var insertPosition = "Below";
		if (targetNode.isPaging) {
			insertPosition = "Above";
		}
		var config = {
			targetRowPrimaryColumnValue: (targetNode.isRoot ? null : targetNode.id),
			insertPosition: insertPosition
		};
		if (editAfterInsert) {
			config.attributes = { editAfterInsert: true };
		}
		this.dataSource.insert(config);
	},

	removeSelectedRows: function () {
		var selModel = this.getSelectionModel();
		var selNodes = selModel.selNodes;
		for (var i = 0, count = selNodes.length; i < count; i++) {
			var node = selNodes[i];
			//todo реализовать множественное удаление за один запрос
			this.dataSource.remove({
				primaryColumnValue: node.id,
				attribute: { node: node }
			});
		}
	},

	revertActiveRow: function () {
		var activeRow = this.dataSource.activeRow;
		if (activeRow.hasChanges || (activeRow.state == 'New')) {
			var selModel = this.getSelectionModel();
			var node = selModel.activeNode;
			activeRow.cancel({
				attribute: { node: node }
			});
		}
	},

	onDataSourceRemoved: function (dataSource, cfg) {
		if (!this.rendered) {
			//TODO: CR143389 Реализовать отложенную обработку события
			return;
		}
		cfg = typeof cfg == 'string' ? Ext.decode(cfg) : cfg;
		var primaryColumnValue = cfg.primaryColumnValue;
		var node = this.getNodeById(primaryColumnValue);
		if (!node) {
			return;
		}
		var parent = node.parentNode;
		parent.removeChild(node, false);
		if (parent.childNodes.length == 0) {
			parent.ui.updateExpandIcon();
		}
		this.view.processRows();
		this.view.updateScroll();
		this.markSummaryAsWrong();
	},

	onDataSourceCancel: function (dataSource, data, cfgId) {
		this.onDataSourceRowLoaded(dataSource, data, cfgId);
	},

	onDataSourceRowMoved: function (primaryColumnValue, targetRowPrimaryColumnValue, movePosition) {
		var node = this.getNodeById(primaryColumnValue);
		var targetRow = !Ext.isEmpty(targetRowPrimaryColumnValue) ?
			this.getNodeById(targetRowPrimaryColumnValue) : this.root;
		var updateNode = (movePosition == "Append") ? targetRow : targetRow.parentNode;
		var repaintChildIndent;
		if ((movePosition == "Append") && updateNode.childNodes < 1) {
			updateNode.loaded = true;
			updateNode.setExpandable(true);
		}
		this.suspendEvents();
		try {
			this.appendChildNode(node, updateNode, true, movePosition, targetRow);
		} finally {
			this.resumeEvents();
		}
		updateNode.ui.repaintChildIndent();
		updateNode.dataLoadingComplete();
	},

	onDataSourceRowInserted: function (dataSource, row, cfg) {
		if (!this.rendered) {
			//TODO: CR143389 Реализовать отложенную обработку события
			return;
		}
		var primaryColumnValue = row.getPrimaryColumnValue();
		var targetRowPrimaryColumnValue = cfg.targetRowPrimaryColumnValue;
		var targetRow = !Ext.isEmpty(targetRowPrimaryColumnValue) ?
			this.getNodeById(targetRowPrimaryColumnValue) : this.root;
		var newNode = targetRow.createNode({
			id: primaryColumnValue
		});
		//TODO CR 100902 нет механизма формировать нормальный cfg в методе onInsertResponse EntityDataSource-a
		//Append по умолчанию как временное решение
		var insertPosition = cfg.insertPosition || "Append";
		var updateNode = (insertPosition == "Append") ? targetRow : targetRow.parentNode;
		if ((insertPosition == "Append") && updateNode.childNodes < 1) {
			updateNode.loaded = true;
			updateNode.setExpandable(true);
		}
		this.suspendEvents();
		try {
			this.appendChildNode(newNode, updateNode, true, insertPosition, targetRow);
		} finally {
			this.resumeEvents();
		}
		if (cfg.attributes && cfg.attributes.editAfterInsert) {
			var columnModel = this.getColumnModel();
			var colIndex = columnModel.getFirstEditableColumnIndex();
			var selModel = this.getSelectionModel();
			selModel.select(newNode, false);
			this.editedNode = newNode;
			var row = newNode.ui.elNode.rows[0];
			var cell = row.cells[this.view.getColumnPosition(colIndex)];
			this.view.scrollTo(cell);
			this.editSelectedCell();
		} else {
			updateNode.dataLoadingComplete();
		}
		this.markSummaryAsWrong();
	},

	editNextColumn: function () {
		var columnModel = this.getColumnModel();
		var selectionModel = this.getSelectionModel();
		var colIndex = columnModel.getNextEditableColumnIndex(selectionModel.activeCellIndex);
		if (colIndex == null) {
			return;
		}
		selectionModel.blurActiveCell();
		selectionModel.focusCell(colIndex);
		this.editSelectedCell();
	},

	editPreviousColumn: function () {
		var columnModel = this.getColumnModel();
		var selectionModel = this.getSelectionModel();
		var colIndex = columnModel.getPreviousEditableColumnIndex(selectionModel.activeCellIndex);
		if (colIndex == null) {
			return;
		}
		selectionModel.blurActiveCell();
		selectionModel.focusCell(colIndex);
		this.editSelectedCell();
	},

	unselect: function () {
		var selectionModel = this.getSelectionModel();
		selectionModel.unselect(selectionModel.activeNode);
	},

	addConfigs: function (configs) {
		configs = eval(configs);
		if (!this.configs) {
			this.configs = new Object();
		}
		for (var i = 0; i < configs.length; i++) {
			var config = configs[i];
			var configId = config.id;
			this.configs[configId] = config;
			delete config.id;
		}
	},

	focus: function () {
		if (this.hasFocus !== true || (Ext.isIE)) {
			var focusEl = this.view.focusEl;
			focusEl.focus.defer(10, focusEl);
			this.hasFocus = true;
			Terrasoft.FocusManager.setFocusedControl.defer(10, this, [this]);
		}
	},

	unFocus: function () {
		this.hasFocus = false;
		this.el.removeClass("x-tree-focused");
		this.getSelectionModel().blurActiveCell();
	},

	moveSelectedRowsUp: function () {
		var selectedRows = this.selModel.getSelectedNodesSortedByPosition();
		if (selectedRows.length > 0) {
			var targetRow = selectedRows[0].node.previousSibling;
			if (targetRow) {
				var ids = new Array();
				this.selModel.clearSelections(true);
				for (var i = 0; i < selectedRows.length; i++) {
					var id = selectedRows[i].node.id;
					this.dataSource.move(id, targetRow.id, "Above");
					ids.push(id);
				}
				this.selectNodes(ids, false, true);
			}
		}
	},

	moveSelectedRowsDown: function () {
		var selectedRows = this.selModel.getSelectedNodesSortedByPosition();
		if (selectedRows.length > 0) {
			var count = selectedRows.length;
			var targetRow = selectedRows[count - 1].node.nextSibling;
			if (targetRow) {
				var ids = new Array();
				this.selModel.clearSelections(true);
				for (var i = count - 1; i >= 0; i--) {
					var id = selectedRows[i].node.id;
					this.dataSource.move(id, targetRow.id, "Below");
					ids.push(id);
				}
				this.selectNodes(ids, false, true);
			}
		}
	},

	isColumnAccessDenied: function (column, columnValues) {
		if ((column.isLookup)
				&& Ext.isEmpty(columnValues[column.displayColumnName])
				&& !Ext.isEmpty(columnValues[column.valueColumnName])
				|| !this.dataSource.canReadColumn(column)) {
			return true;
		}
		return false;
	},

	markSummaryAsWrong: function () {
		if (this.isSummaryVisible) {
			var summary = this.getSummaryPlugin();
			if (summary) {
				summary.enableRefreshState(true);
			}
		}
	},

	rerenderData: function () {
		var selectedRows = this.selModel.getSelectedNodesSortedByPosition();
		var ids = new Array();
		for (var i = 0; i < selectedRows.length; i++) {
			var id = selectedRows[i].node.id;
			ids.push(id);
		}
		this.selModel.clearSelections(true);
		this.clear(true);
		var dataSource = this.dataSource;
		var records = new Array();
		var rows = dataSource.rows.items;
		for (var i = 0; i < rows.length; i++) {
			records.push(rows[i].columns);
		}
		this.onDataSourceLoaded(dataSource, records, { add: true });
		this.selectNodes(ids, true, true);
	},

	disable: function () {
		Terrasoft.TreeGrid.superclass.disable.call(this);
		this.onDisableChange(true);
	},

	enable: function () {
		Terrasoft.TreeGrid.superclass.enable.call(this);
		this.onDisableChange(false);

	},

	onDisableChange: function(state) {
		if (state) {
			this.addClass("x-tree-disabled");
		} else {
			this.removeClass("x-tree-disabled");
		}
		var bottomToolbar = this.bottomToolbar;
		if (bottomToolbar) {
			if (state) {
				bottomToolbar.disable();
			} else {
				bottomToolbar.enable();
			}
		}
		var selModel = this.getSelectionModel();
		if (selModel && selModel.activeNode) {
			if (state) {
				selModel.unselect(selModel.activeNode);
			} else {
				selModel.select(selModel.activeNode);
			}
		}
	},

	isVisible: function(deep) {
		return this.rendered && this.getActionEl().isVisible(deep);
	}
});

Ext.reg("terrasofttreegrid", Terrasoft.TreeGrid);

Terrasoft.TreeGrid.PagingToolbar = function(owner, single) {
	var className = "x-treegrid-pagingtoolbar";
	if (single) {
		className += " single";
	}
	Terrasoft.TreeGrid.PagingToolbar.superclass.constructor.call(this, {
		id: "pagingToolbar",
		owner: owner,
		className: className
	});
};

Ext.extend(Terrasoft.TreeGrid.PagingToolbar, Terrasoft.Tools.Toolbar, {
	
	createPagingEdit: function(){
		var pageNumber = document.createElement("div");
		pageNumber.className = "x-tbar-page-number";
		return new Terrasoft.Tools.Item(pageNumber);
	},
	
	setPage: function(page) {
		this.currentPage = page;
		var pagingEdit = this.items.get("pagingEdit");
		if (pagingEdit) {
			pagingEdit.el.innerHTML = page;
		}
	},

	actualizePagingNavigationButtons: function(){
		var treegrid = this.owner;
		var structure = treegrid.structure;
		var buttons = this.items;
		var nextPageButton = buttons.get("nextPage");
		var firstPageButton = buttons.get("firstPage");
		var previousPageButton = buttons.get("previousPage");
		var hasNextPage = treegrid.root.hasNextPage;
		nextPageButton.disable();
		firstPageButton.disable();
		previousPageButton.disable();
		if (hasNextPage) {
			nextPageButton.enable();
		} else {
			nextPageButton.disable();
		}
		if (this.currentPage == 1) {
			firstPageButton.disable();
			previousPageButton.disable();
		} else {
			firstPageButton.enable();
			previousPageButton.enable();
		}
	} ,

	enable: function() {
		Terrasoft.TreeGrid.PagingToolbar.superclass.enable.call(this);
		this.actualizePagingNavigationButtons();
	}

});

Ext.reg('pagingtoolbar', Terrasoft.TreeGrid.PagingToolbar);

Terrasoft.QuickFilter = function(treegrid) {
	Terrasoft.QuickFilter.superclass.constructor.call(this, {
		id: "quickFilter",
		owner: treegrid,
		className: "x-treegrid-quickfilter"
	});
	this.filterGroupName = "QuickFilter";
	this.scrollStep = 10;
	this.addQuickFilterElements();
};

Ext.extend(Terrasoft.QuickFilter, Terrasoft.Tools.Toolbar, {

	initializeDataSourceFilters: function () {
		this.filters = this.owner.dataSource.structure.filters;
		this.filters.on("added", this.onDataSourceAddFilter, this);
		this.filters.on("inserted", this.onDataSourceAddFilter, this);
		this.filters.on("removed", this.onDataSourceRemoveFilter, this);
		this.filters.on("updated", this.onDataSourceUpdateFilter, this);
	},

	addQuickFilterElements: function () {
		var addFilter = new Terrasoft.ToolButton({
			handler: this.onClick.createDelegate(this, ["add"]),
			cls: "x-toolbutton-add"
		});
		this.addItem(addFilter, "add");
		var quickAddFilter = new Terrasoft.ToolButton({
			handler: this.onClick.createDelegate(this, ["quickadd"]),
			cls: "x-toolbutton-add-flash"
		});
		this.addItem(quickAddFilter, "quickadd");
		var removeFilters = new Terrasoft.ToolButton({
			handler: this.onClick.createDelegate(this, ["removeall"]),
			cls: "x-toolbutton-remove"
		});
		this.addItem(removeFilters, "removeall");
		var scrollLeft = new Terrasoft.ToolButton({
			cls: "x-toolbutton-previousPage"
		});
		this.addItem(scrollLeft, "scrollleft");
		this.addItem(new Terrasoft.Tools.Container(), "filtercontainer");
		var scrollRight = new Terrasoft.ToolButton({
			cls: "x-toolbutton-nextPage"
		});
		this.addItem(scrollRight, "scrollright");
		this.addItem(new Terrasoft.Tools.Separator(), "separator");
	},

	afterRender: function () {
		var scrollLeft = this.items.get("scrollleft");
		new Ext.util.ClickRepeater(scrollLeft.el, {
			handler: this.scrollLeft,
			scope: this
		});
		var scrollRight = this.items.get("scrollright");
		new Ext.util.ClickRepeater(scrollRight.el, {
			handler: this.scrollRight,
			scope: this
		});
		this.actualizeRemoveFiltersButton();
		if (this.owner.designMode) {
			this.disable();
		} else {
			this.actualizeScrollButtons();
		}
		this.owner.on("resize", this.onTreegridResize, this);
	},

	onTreegridResize: function () {
		var filterContainer = this.items.get("filtercontainer");
		var scrollElement = filterContainer.el;
		scrollElement.scrollLeft = 0;
		this.actualizeScrollButtons();
	},

	scrollLeft: function () {
		var filterContainer = this.items.get("filtercontainer");
		var scrollElement = filterContainer.el;
		scrollElement.scrollLeft -= this.scrollStep;
		this.actualizeScrollButtons();
	},

	scrollRight: function () {
		var filterContainer = this.items.get("filtercontainer");
		var scrollElement = filterContainer.el;
		scrollElement.scrollLeft += this.scrollStep;
		this.actualizeScrollButtons();
	},

	onClick: function (which) {
		switch (which) {
			case "add":
				var initColumn = this.getInitColumn();
				if (initColumn) {
					this.showEditWindow();
				} else {
					var stringList = Ext.StringList('WC.TreeGrid');
					Ext.MessageBox.show({
						caption: stringList.getValue("QuickFilter.EditWindowCaption"),
						msg: stringList.getValue("QuickFilter.IncorrectQuickFilterColumn"),
						buttons: Ext.MessageBox.OK,
						icon: Ext.MessageBox.INFO
					});
				}
				break;
			case "quickadd":
				this.addSelectedValueFilter();
				break;
			case "removeall":
				this.removeFilters();
				break;
		}
	},

	renderFilter: function (item) {
		var filter = new Terrasoft.Tools.QuickFilterItem({
			dataSourceFilter: item,
			filterClick: this.onFilterClick.createDelegate(this, [item.uId]),
			triggerClick: this.onTriggerClick.createDelegate(this, [item.uId])
		});
		var filterContainer = this.items.get("filtercontainer");
		filterContainer.addItem(filter, item.uId);
	},

	onDataSourceAddFilter: function (item) {
		if (!this.isNeedProcessingOnEvent(item)) {
			return;
		}
		if (this.itemIsFiltersGroup(item)) {
			var filters = item.items;
			for (var i = 0; i < filters.length; i++) {
				this.renderFilter(filters.items[i]);
			}
		} else {
			this.renderFilter(item);
		}
		this.actualizeRemoveFiltersButton();
		this.actualizeScrollButtons();
		this.owner.hideLoadMask(this.owner.root);
	},

	removeFilters: function () {
		var group = this.findDataSourceQuickFilterGroup();
		this.owner.showLoadMask(this.owner.root);
		this.owner.clear();
		group.parentGroup.remove(group.uId, true);
	},

	onFilterClick: function (id) {
		this.showEditWindow(id);
	},

	onTriggerClick: function (id) {
		var parentGroup = this.findDataSourceQuickFilterGroup();
		this.owner.showLoadMask(this.owner.root);
		this.owner.clear();
		parentGroup.remove(id, true);
	},

	onDataSourceRemoveFilter: function (item) {
		var firstLevelGroup = item.getFirstLevelGroup();
		if (firstLevelGroup.name != this.filterGroupName) {
			return;
		}
		var filterContainer = this.items.get("filtercontainer");
		if (this.itemIsFiltersGroup(item)) {
			filterContainer.clear();
		} else {
			filterContainer.removeItem(item.uId);
			var scrollElement = filterContainer.el;
			scrollElement.scrollLeft = 0;
		}
		this.actualizeScrollButtons();
		this.actualizeRemoveFiltersButton();
		this.owner.hideLoadMask(this.owner.root);
	},

	clientClear: function () {
		var filterContainer = this.items.get("filtercontainer");
		if (filterContainer && filterContainer.items.length > 0) {
			filterContainer.clear();
		}
	},

	actualize: function () {
		var filterContainer = this.items.get("filtercontainer");
		if (filterContainer && (filterContainer.length > 0)) {
			this.clientClear();
		}
		var quickFilterGroup = this.findDataSourceQuickFilterGroup();
		if (quickFilterGroup) {
			var filters = quickFilterGroup.items;
			for (var i = 0; i < filters.length; i++) {
				this.renderFilter(filters.items[i]);
			}
		}
		this.actualizeScrollButtons();
		this.actualizeRemoveFiltersButton();
	},

	onDataSourceUpdateFilter: function (item) {
		var firstLevelGroup = item.getFirstLevelGroup();
		if (firstLevelGroup.name != this.filterGroupName) {
			return;
		}
		var filterContainer = this.items.get("filtercontainer");
		var filter = filterContainer.items.get(item.uId);
		if (filter) {
			filter.rerender();
		}
		this.owner.hideLoadMask(this.owner.root);
	},

	onColumnSelect: function (comboBox, rowParameter, index) {
		var editWindow = this.editWindow;
		if (editWindow.valueEditor) {
			editWindow.editLayout.removeControl(editWindow.valueEditor);
		}
		var row = Ext.decode(rowParameter);
		var columnUId = row.value;
		var column = this.owner.dataSource.getColumnByUId(columnUId);
		editWindow.valueEditor = this.getEditorByColumn(column);
		editWindow.editLayout.add(editWindow.valueEditor);
		editWindow.editLayout.updateControlsCaptionWidth();
		editWindow.valueEditor.focus(false, 10);
	},

	actualizeScrollButtons: function () {
		var filterContainer = this.items.get("filtercontainer");
		var scrollLeft = this.items.get("scrollleft");
		var scrollRight = this.items.get("scrollright");
		var separator = this.items.get("separator");
		var scrollElement = Ext.get(filterContainer.el);
		var scrollClass = "x-scroll";
		if ((scrollElement.dom.scrollWidth > scrollElement.dom.offsetWidth)
				&& filterContainer.items.length > 0) {
			scrollElement.addClass(scrollClass);
			scrollLeft.show();
			scrollRight.show();
			separator.show();
		} else {
			scrollElement.removeClass(scrollClass);
			scrollLeft.hide();
			scrollRight.hide();
			separator.hide();
		}
		if (scrollElement.dom.scrollLeft == 0) {
			scrollLeft.disable();
		} else {
			scrollLeft.enable();
		}
		if (scrollElement.dom.scrollLeft == scrollElement.dom.scrollWidth - scrollElement.dom.offsetWidth) {
			scrollRight.disable();
		} else {
			scrollRight.enable();
		}
	},

	actualizeRemoveFiltersButton: function () {
		var button = this.items.get("removeall");
		var filterContainer = this.items.get("filtercontainer");
		var count = filterContainer.items.length;
		if (count > 0) {
			button.show();
		} else {
			button.hide();
		}
	},

	addSelectedValueFilter: function () {
		var column = this.getInitColumn();
		var treegrid = this.owner;
		var selModel = treegrid.getSelectionModel();
		var selNode = selModel.activeNode;
		var row = selNode ? treegrid.dataSource.getRow(selNode.id) : null;
		var columnName = column.name;
		var value = row ? row.getColumnValue(columnName) : '';
		var displayValue = row ? row.getColumnDisplayValue(columnName) : '';
		this.addNewQuickFilter(column, value, displayValue);
		treegrid.showLoadMask(this.owner.root);
		treegrid.clear();
	},

	prepareValueByType: function (value, type) {
		switch (type) {
			case 'Float1':
			case 'Float2':
			case 'Float3':
			case 'Float4':
			case 'Money':
				var decimalSeparator = Terrasoft.CultureInfo.decimalSeparator;
				value = value.replace(decimalSeparator, ".");
				break;
		}
		return value;
	},

	showEditWindow: function (filterId) {
		if (!this.editWindow) {
			this.editWindow = this.createQuickFilterEditWindow();
			this.addEditControls(this.editWindow);
		}
		this.editWindow.show();
		this.setFilterValues(this.editWindow, filterId);
		if (this.editWindow.valueEditor) {
			this.editWindow.valueEditor.focus(false, 10);
		}
	},

	createQuickFilterEditWindow: function () {
		var stringList = Ext.StringList('WC.TreeGrid');
		var window = new Terrasoft.Window({
			caption: this.caption,
			width: 400,
			height: 140,
			modal: true,
			frameStyle: 'padding: 0',
			resizable: false,
			closeAction: 'hide',
			caption: stringList.getValue("QuickFilter.EditWindowCaption")
		});
		return window;
	},

	addEditControls: function (editWindow) {
		var mainLayout = new Terrasoft.ControlLayout({
			direction: 'vertical',
			height: '100%',
			width: '100%'
		});
		this.addColumsComboBox(mainLayout);
		this.addButtons(mainLayout);
		editWindow.add(mainLayout);
	},

	addColumsComboBox: function (mainLayout) {
		var editWindow = this.editWindow;
		editWindow.editLayout = new Terrasoft.ControlLayout({
			direction: 'vertical',
			width: '100%',
			height: '100%',
			layoutConfig: {
				padding: '5',
				defaultMargins: '5'
			}
		});
		var stringList = Ext.StringList("WC.TreeGrid");
		editWindow.columnsEditor = new Terrasoft.ComboBox({
			caption: stringList.getValue("QuickFilter.Column"),
			width: '100%'
		});
		editWindow.columnsEditor.isLocalList = true;
		editWindow.columnsEditor.on("select", this.onColumnSelect, this);
		editWindow.editLayout.add(editWindow.columnsEditor);
		editWindow.columnsEditor.store.setDefaultSort("text");
		mainLayout.add(editWindow.editLayout);
	},

	getColumns: function (columnModel) {
		var columns = new Array();
		for (var i = 0; i < columnModel.config.length; i++) {
			var structureColumn = columnModel.config[i];
			if (structureColumn.isVisible) {
				var column = new Array();
				column.push(structureColumn.uId);
				column.push(structureColumn.caption);
				columns.push(column);
			}
		}
		return columns;
	},

	addButtons: function (mainLayout) {
		var buttonsLayout = new Terrasoft.ControlLayout({
			align: 'middle',
			direction: 'horizontal',
			fitHeightByContent: true,
			width: '100%',
			displayStyle: 'footer',
			layoutConfig: {
				padding: '3',
				defaultMargins: '3'
			}
		});
		var stringListCommon = Ext.StringList('WC.Common');
		var spacer = new Ext.Spacer({ size: '100%' });
		buttonsLayout.add(spacer);
		var okButton = new Terrasoft.Button({
			id: 'okButton',
			defaultButton: true,
			caption: stringListCommon.getValue('Button.Ok'),
			handler: this.onEditComplete.createDelegate(this)
		});
		buttonsLayout.add(okButton);
		var cancelButton = new Terrasoft.Button({
			id: 'cancelButton',
			cancelButton: true,
			caption: stringListCommon.getValue('Button.Cancel'),
			handler: this.onCloseWindow.createDelegate(this)
		});
		buttonsLayout.add(cancelButton);
		mainLayout.add(buttonsLayout);
	},

	onCloseWindow: function () {
		this.editWindow.close();
	},

	onEditComplete: function() {
		var valueEditor = this.editWindow.valueEditor;
		if (!valueEditor.validate()) {
			return;
		}
		var columnUId = this.editWindow.columnsEditor.getValue();
		var value = this.editWindow.valueEditor.getValue();
		var displayValue = this.editWindow.valueEditor.getDisplayValue();
		var filterId = this.editWindow.filterId;
		var columnModel = this.owner.getColumnModel();
		var column = columnModel.getColumnByUId(columnUId);
		if (Ext.isEmpty(value) && column.dataValueType.isNumeric) {
			value = 0;
		}
		this.editWindow.close();
		if (filterId) {
			this.updateQuickFilter(filterId, column, value, displayValue);
		} else {
			this.addNewQuickFilter(column, value, displayValue);
		}
		this.owner.showLoadMask(this.owner.root);
		this.owner.clear();
	},

	addNewQuickFilter: function(column, value, displayValue) {
		var dataValueTypeName = column.dataValueType.name;
		var comparisonType = this.getComparisonTypeByDataValueTypeName(dataValueTypeName, value);
		var metaPath = column.metaPath;
		var useDisplayValue = (column.isLookup) && !Ext.isEmpty(value);
		var rightExpression = new Array();
		if (comparisonType != Terrasoft.Filter.ComparisonType.IS_NULL) {
			if (Ext.isEmpty(value)) {
				rightExpression.push({ displayValue: "", parameterValue: "" });
			} else {
				rightExpression.push({ displayValue: displayValue, parameterValue: value });
			}
		}
		var newFilter = this.filters.createFilterWithParameters(comparisonType, metaPath, rightExpression);
		newFilter.useDisplayValue = useDisplayValue;
		if ((dataValueTypeName == 'DateTime') || (dataValueTypeName == 'Date')) {
			newFilter.trimDateTimeParameterToDate = true;
		}
		newFilter.rightExpression.dataValueType = column.dataValueType;
		if (column.aggregationType) {
			newFilter.leftExpression.expressionType = Terrasoft.Filter.ExpressionType.AGGREGATION;
			newFilter.leftExpression.aggregationType = column.aggregationType;
			newFilter.leftExpression.caption = column.caption;
			var serializedSubFilters = column.subFilters;
			if (serializedSubFilters) {
				newFilter.subFilters = Ext.decode(serializedSubFilters);
			}
		}
		var parentGroup = this.findDataSourceQuickFilterGroup();
		if (!parentGroup) {
			parentGroup = this.filters.createGroup({
				logicalOperation: Terrasoft.Filter.LogicalOperation.AND,
				name: this.filterGroupName
			});
			parentGroup.internalAdd(newFilter);
			this.filters.add(parentGroup, true);
		} else {
			var subFilters = newFilter.subFilters;
			if (subFilters) {
				newFilter.subFilters = new Terrasoft.FiltersGroup(subFilters);
			}
			parentGroup.add(newFilter, true);
		}
	},

	getComparisonTypeByDataValueTypeName: function(dataValueTypeName, value) {
		switch (dataValueTypeName) {
			case 'Text':
			case 'MaxSizeText':
			case 'HashText':
			case 'SecureText':
			case 'ShortText':
			case 'MediumText':
			case 'LongText':
				if (!Ext.isEmpty(value)) {
					if (this.owner.stringColumnSearchComparisonType) {
						return this.owner.stringColumnSearchComparisonType;
					} else {
						return Terrasoft.Filter.ComparisonType.CONTAIN;
					}
				} else {
					return Terrasoft.Filter.ComparisonType.EQUAL;
				}
				break;
			case 'Lookup':
				if (!Ext.isEmpty(value)) {
					if (this.owner.stringColumnSearchComparisonType) {
						return this.owner.stringColumnSearchComparisonType;
					} else {
						return Terrasoft.Filter.ComparisonType.CONTAIN;
					}
				} else {
					return Terrasoft.Filter.ComparisonType.IS_NULL;
				}
				break;
			case 'DateTime':
			case 'Date':
			case 'Time':
				if (!Ext.isEmpty(value)) {
					return Terrasoft.Filter.ComparisonType.EQUAL;
				} else {
					return Terrasoft.Filter.ComparisonType.IS_NULL;
				}
				break;
			default:
				return Terrasoft.Filter.ComparisonType.EQUAL;
				break;
		}
	},

	updateQuickFilter: function(filterId, column, value, displayValue) {
		var filterContainer = this.items.get("filtercontainer");
		var filter = filterContainer.items.get(filterId);
		var metaPath = column.metaPath;
		var useDisplayValue = (column.isLookup) && !Ext.isEmpty(value);
		var dataSourceFilter = filter.dataSourceFilter;
		dataSourceFilter.useDisplayValue = useDisplayValue;
		var leftExpression = dataSourceFilter.leftExpression;
		leftExpression.metaPath = metaPath;
		leftExpression.caption = column.caption;
		var dataValueType = column.dataValueType;
		var dataValueTypeName = dataValueType.name;
		if ((dataValueTypeName == 'DateTime') || (dataValueTypeName == 'Date')) {
			dataSourceFilter.trimDateTimeParameterToDate = true;
		}
		var comparisonType = this.getComparisonTypeByDataValueTypeName(dataValueTypeName, value);
		dataSourceFilter.comparisonType = comparisonType;
		if (comparisonType == Terrasoft.Filter.ComparisonType.IS_NULL) {
			delete dataSourceFilter.rightExpression;
		} else {
			var rightExpression = dataSourceFilter.rightExpression;
			if (!rightExpression || Ext.isEmptyObj(rightExpression)) {
				dataSourceFilter.rightExpression = rightExpression = {
					expressionType: Terrasoft.Filter.ExpressionType.PARAMETER
				};
			}
			rightExpression.dataValueType = dataValueType;
			rightExpression.parameterValues = [];
			rightExpression.parameterValues.push({
				displayValue: displayValue,
				parameterValue: value
			});
		}
		dataSourceFilter.synchronize(true);
	},

	setFilterValues: function(window, filterId) {
		var columnModel = this.owner.getColumnModel();
		var columns = this.getColumns(columnModel);
		window.columnsEditor.list = undefined;
		window.columnsEditor.loadData(columns);
		window.filterId = filterId;
		if (filterId) {
			var filterContainer = this.items.get("filtercontainer");
			var filter = filterContainer.items.get(filterId);
			var dataSourceFilter = filter.dataSourceFilter;
			var metaPath = dataSourceFilter.leftExpression.metaPath;
			if (dataSourceFilter.useDisplayValue) {
				var lastDelimeterPosition = metaPath.lastIndexOf('.');
				if (lastDelimeterPosition != -1) {
					metaPath = metaPath.substr(0, lastDelimeterPosition);
				}
			}
			var column = columnModel.getColumnByMetaPath(metaPath);
			var parameterValues = null;
			var rightExpression = dataSourceFilter.rightExpression;
			if (rightExpression != null && !Ext.isEmptyObj(rightExpression)) {
				parameterValues = rightExpression.parameterValues[0];
			}
			var parameterValue = null;
			if (parameterValues) {
				parameterValue = dataSourceFilter.useDisplayValue
					? parameterValues.displayValue
					: parameterValues.parameterValue;
			}
			window.columnsEditor.setValueAndFireSelect(column.uId);
			if (window.valueEditor) {
				window.valueEditor.setValue(parameterValue);
			}
		} else {
			var initColumn = this.getInitColumn();
			window.columnsEditor.setValueAndFireSelect(initColumn.uId);
			var initValue = this.getInitValue(initColumn);
			if (window.valueEditor) {
				window.valueEditor.setValue(initValue);
			}
		}
	},

	getInitColumn: function () {
		var selModel = this.owner.getSelectionModel();
		var colIndex = selModel.activeCellIndex;
		var colModel = this.owner.getColumnModel();
		var column;
		if (colIndex) {
			column = colModel.getColumn(colIndex);
		} else {
			var column = colModel.getFirstVisibleColumn();
		}
		return column;

	},

	getInitValue: function (column) {
		if (!column) {
			return null;
		}
		var selModel = this.owner.getSelectionModel();
		var selNode = selModel.activeNode;
		if (!selNode) {
			return null;
		}
		var colModel = this.owner.getColumnModel();
		var dataSource = this.owner.dataSource;
		var row = dataSource.getRow(selNode.id);
		var columnName;
		if (column.isLookup) {
			columnName = column.displayColumnName;
		} else {
			columnName = column.name;
		}
		var initValue = row.getColumnValue(columnName);
		return initValue;
	},

	getEditorByColumn: function (column) {
		var dataValueType = column.dataValueType;
		var xtype = dataValueType.editor.controlXType;
		var defaultConfiguration = this.getEditorConfig(dataValueType, xtype);
		if ((xtype == 'lookupedit') || (xtype == 'combobox')) {
			xtype = 'textedit';
		}
		var editor = Ext.ComponentMgr.create(defaultConfiguration, xtype);
		return editor;
	},

	getEditorConfig: function (dataValueType, xtype) {
		var defaultConfiguration = dataValueType.editor.defaultConfiguration;
		var config = Ext.isEmpty(defaultConfiguration) ? {} : Ext.decode(defaultConfiguration);
		config.selectOnFocus = true;
		config.width = '100%';
		var stringList = Ext.StringList('WC.TreeGrid');
		config.caption = stringList.getValue('QuickFilter.Value');
		switch (xtype) {
			case 'checkbox':
				config.captionPosition = 'left';
				break;
			case 'coloredit':
				config.displayMode = 'Both';
				break;
			case 'memoedit':
				config.height = 42;
				this.editWindow.setSize(this.editWindow.width, 160);
				break;
			case 'datetimeedit':
				if (config.kind == 'datetime') {
					config.kind = 'date';
				}
				break;
			case 'floatedit':
				config.decimalPrecision = dataValueType.precision;
				break;
			default:
				this.editWindow.setSize(this.editWindow.width, 140);
				break;
		}
		return config;
	},

	findDataSourceQuickFilterGroup: function () {
		var group = this.findGroupByName(this.filters, this.filterGroupName);
		return group;
	},

	findGroupByName: function (parentGroup, groupName) {
		var children = parentGroup.items;
		for (var i = 0; i < children.length; i++) {
			var child = children.items[i];
			if (!this.itemIsFiltersGroup(child)) {
				continue;
			}
			if (child.name == groupName) {
				return child;
			}
		}
		return null;
	},

	itemIsFiltersGroup: function (item) {
		return item instanceof Terrasoft.FiltersGroup;
	},

	isNeedProcessingOnEvent: function (item) {
		var firstLevelGroup = item.getFirstLevelGroup();
		if (firstLevelGroup.name != this.filterGroupName) {
			return false;
		}
		return true;
	}
});

Ext.reg('quickfilter', Terrasoft.QuickFilter);

Ext.treegrid.TreeNodeUI = function(node) {
	this.node = node;
	this.rendered = false;
	this.animating = false;
	this.wasLeaf = true;
	this.emptyIcon = Ext.BLANK_IMAGE_URL;
};

Ext.treegrid.TreeNodeUI.prototype = {

	removeChild: function(node) {
		if (this.rendered) {
			this.ctNode.removeChild(node.ui.getEl());
		}
	},

	enableLoadingState: function(enabled){
		var loadingClass = "x-tree-node-loading";
		var ecNode = Ext.get(this.ecNode);
		if (ecNode) {
			if (enabled){
				ecNode.addClass(loadingClass);
			} else {
				ecNode.removeClass(loadingClass);
			}
		}
	},

	onValueChange: function(value, col) {
		var row = this.elNode.rows[0];
		var treegrid = this.node.getTreeGrid();
		var view = treegrid.view;
		var cell = row.cells[view.getColumnPosition(col)];
		var columnModel = treegrid.getColumnModel();
		var column = columnModel.getColumn(col);
		if (column.dataValueType.name == "Boolean"){
			view.setBoolCellValue(cell, value);
		} else {
			view.setCellValue(cell, value);
			this.clearCellIcons(cell);
		}	
	},

	onDisableChange: function(node, state) {
		this.disabled = state;
		if (this.checkbox) {
			this.checkbox.disabled = state;
		}
		if (state) {
			this.addClass("x-tree-node-disabled");
		} else {
			this.removeClass("x-tree-node-disabled");
		}
	},

	onSelectedChange: function(state) {
		var row = Ext.get(this.elNode);
		if (!row) {
			return;
		}
		var previewer = Ext.get(this.prevNode);
		var treegrid = this.node.getTreeGrid();
		var cls = "x-tree-selected" + (Terrasoft.TreeGridSelectionStyle === 1 ? "-edging" : "");
		if (state) {
			row.addClass(cls);
			if (previewer) {
				previewer.addClass(cls);
			}
		} else {
			row.removeClass(cls);
			if (previewer) {
				previewer.removeClass(cls);
			}
		}
	},

	onMove: function(treegrid, node, oldParent, newParent, index, refNode) {

	},

	addClass: function(cls) {
		if (this.elNode) {
			Ext.fly(this.elNode.parentNode).addClass(cls);
		}
	},

	removeClass: function(cls) {
		if (this.elNode) {
			Ext.fly(this.elNode.parentNode).removeClass(cls);
		}
	},

	remove: function() {
		if (this.rendered && this.wrap) {
			this.holder = document.createElement("div");
			this.holder.appendChild(this.wrap);
		}
	},

	fireEvent: function() {
		return this.node.fireEvent.apply(this.node, arguments);
	},

	initEvents: function() {
		this.node.on("move", this.onMove, this);
		if (this.node.disabled) {
			this.addClass("x-tree-node-disabled");
			if (this.checkbox) {
				this.checkbox.disabled = true;
			}
		}
		if (this.node.hidden) {
			this.hide();
		}
	},

	hide: function() {
		this.node.hidden = true;
		if (this.wrap) {
			this.wrap.style.display = "none";
		}
	},

	show: function() {
		this.node.hidden = false;
		if (this.wrap) {
			this.wrap.style.display = "";
		}
	},

	onContextMenu: function(e) {
		if (this.node.hasListener("contextmenu") || this.node.getTreeGrid().hasListener("contextmenu")) {
			//TODO на данный момент этот обработчик не нужен, но уверен, что это пригодится
			//e.preventDefault();
			//this.focus();
			//this.fireEvent("contextmenu", this.node, e);
		}
	},

	onClick: function(e) {
		if (this.dropping) {
			e.stopEvent();
			return;
		}
		if (this.fireEvent("beforeclick", this.node, e) !== false) {
			var a = e.getTarget('a');
			if (!this.disabled && this.node.attributes.href && a) {
				this.fireEvent("click", this.node, e);
				return;
			} else if (a && e.ctrlKey) {
				e.stopEvent();
			}
			e.preventDefault();
			if (this.disabled) {
				return;
			}
			if (this.node.attributes.singleClickExpand && !this.animating && this.node.isExpandable()) {
				this.node.toggle();
			}
			this.fireEvent("click", this.node, e);
		} else {
			e.stopEvent();
		}
	},

	onDblClick: function(e) {
		e.preventDefault();
		if (this.disabled) {
			return;
		}
		if (this.checkbox) {
			this.toggleCheck();
		}
		this.fireEvent("dblclick", this.node, e);
	},

	onOver: function(e) {
		this.addClass('x-tree-node-over');
	},

	onOut: function(e) {
		this.removeClass('x-tree-node-over');
	},

	onCheckChange: function() {
		var checked = this.checkbox.checked;
		this.checkbox.defaultChecked = checked;
		this.node.attributes.checked = checked;
		this.fireEvent('checkchange', this.node, checked);
	},

	ecClick: function() {
		if (!this.animating && this.node.isExpandable()) {
			this.node.toggle();
		}
	},

	preview: function() {
		var quickView = this.node.getTreeGrid().quickView;
		if (this.isQuickViewVisible) {
			quickView.hide(this);
			var view = this.node.treegrid.view;
			view.updateScroll();
		} else {
			quickView.show(this);
		}
	},

	startDrop: function() {
		this.dropping = true;
	},

	endDrop: function() {
		setTimeout(function() {
			this.dropping = false;
		} .createDelegate(this), 50);
	},

	expand: function() {
		this.updateExpandIcon();
		this.ctNode.style.display = "";
	},

	focus: function() {
		if (!this.node.preventHScroll) {
			try {
				this.anchor.focus();
			} catch (e) { }
		} else if (!Ext.isIE) {
			try {
				var noscroll = this.node.getTreeGrid().getTreeEl().dom;
				var l = noscroll.scrollLeft;
				this.anchor.focus();
				noscroll.scrollLeft = l;
			} catch (e) { }
		}
	},

	toggleCheck: function(value) {
		var cb = this.checkbox;
		if (cb) {
			cb.checked = (value === undefined ? !cb.checked : value);
			this.onCheckChange();
		}
	},

	blur: function() {
		try {
			this.anchor.blur();
		} catch (e) { }
	},

	animExpand: function(callback) {
		var ct = Ext.get(this.ctNode);
		ct.stopFx();
		if (!this.node.isExpandable()) {
			this.updateExpandIcon();
			this.ctNode.style.display = "";
			Ext.callback(callback);
			return;
		}
		this.animating = true;
		this.updateExpandIcon();

		ct.slideIn('t', {
			callback: function() {
				this.animating = false;
				Ext.callback(callback);
			},
			scope: this,
			duration: this.node.treegrid.duration || .25
		});
	},

	highlight: function() {
		var treegrid = this.node.getTreeGrid();
		Ext.fly(this.wrap).highlight(
						treegrid.hlColor || "C3DAF9",
						{ endColor: treegrid.hlBaseColor }
				);
	},

	collapse: function() {
		this.updateExpandIcon();
		this.ctNode.style.display = "none";
	},

	animCollapse: function(callback) {
		var ct = Ext.get(this.ctNode);
		ct.enableDisplayMode('block');
		ct.stopFx();

		this.animating = true;
		this.updateExpandIcon();

		ct.slideOut('t', {
			callback: function() {
				this.animating = false;
				Ext.callback(callback);
			},
			scope: this,
			duration: this.node.treegrid.duration || .25
		});
	},

	getContainer: function() {
		return this.ctNode;
	},

	getEl: function() {
		return this.wrap;
	},

	appendDDGhost: function(ghostNode) {
		ghostNode.appendChild(this.elNode.cloneNode(true));
	},

	getDDRepairXY: function() {
		return this.elNode ? Ext.lib.Dom.getXY(this.elNode) : null;
	},

	onRender: function() {
		this.render();
	},

	rerender: function() {
		this.childIndent = null;
		this.rendered = false;
		this.render();
		if (this.node.isLast() && this.node.previousSibling) {
			this.node.previousSibling.ui.repaintChildIndent();
		}
	},

	render: function(targetNode, bulkRender) {
		var n = this.node, a = n.attributes;
		targetNode = targetNode || n.parentNode ? n.parentNode.ui.getContainer() : n.treegrid.innerCt.dom;
		if (!this.rendered) {
			this.rendered = true;
			this.renderElements(targetNode, bulkRender);
			if (a.qtip) {
				if (this.textNode.setAttributeNS) {
					this.textNode.setAttributeNS("ext", "qtip", a.qtip);
					if (a.qtipTitle) {
						this.textNode.setAttributeNS("ext", "qtitle", a.qtipTitle);
					}
				} else {
					this.textNode.setAttribute("ext:qtip", a.qtip);
					if (a.qtipTitle) {
						this.textNode.setAttribute("ext:qtitle", a.qtipTitle);
					}
				}
			} else if (a.qtipCfg) {
				a.qtipCfg.target = Ext.id(this.textNode);
				Ext.QuickTips.register(a.qtipCfg);
			}
			this.initEvents();
			if ((!this.node.expanded) && (n.treegrid.isTreeMode())) {
				if (this.node.treegrid.columnModel.hasVisibleColumns()) {
					this.updateExpandIcon();
				}
			}
		} else {
			if ((bulkRender === true) && (this.wrap)) {
				targetNode.appendChild(this.wrap);
			}
		}
	},

	renderElements: function(targetNode, bulkRender) {
		
	},

	getAnchor: function() {
		return this.anchor;
	},

	getTextEl: function() {
		return this.textNode;
	},

	isChecked: function() {
		return this.checkbox ? this.checkbox.checked : false;
	},

	updateExpandIcon: function(deep) {
		if (this.rendered) {
			var n = this.node, c1, c2;
			var cls = "x-tree-icon ";
			if (n.parentNode && n.parentNode.isRoot) {
				cls += "root-node ";
			}
			cls += n.isLast() ? "x-tree-elbow-end" : "x-tree-elbow";
			if (n.isExpandable()) {
				if (n.expanded) {
					cls += "-minus";
					c1 = "x-tree-node-collapsed";
					c2 = "x-tree-node-expanded";
				} else {
					cls += "-plus";
					c1 = "x-tree-node-expanded";
					c2 = "x-tree-node-collapsed";
				}
				if (this.wasLeaf) {
					this.removeClass("x-tree-node-leaf");
					this.wasLeaf = false;
				}
				if (this.c1 != c1 || this.c2 != c2) {
					Ext.fly(this.elNode).replaceClass(c1, c2);
					this.c1 = c1; this.c2 = c2;
				}
			} else {
				if (!this.wasLeaf) {
					Ext.fly(this.elNode).replaceClass("x-tree-node-expanded", "x-tree-node-leaf");
					delete this.c1;
					delete this.c2;
					this.wasLeaf = true;
				}
			}
			if ((this.ecNode) && (this.ecNode.className != cls)) {
				this.ecNode.className = cls;
			}
		}
		if (deep) {
			this.updateChildExpandIcons(true);
		}
	},

	updateChildExpandIcons: function(deep) {
		var cs = this.node.childNodes;
		if (!cs) {
			return;
		}
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i].ui.updateExpandIcon(deep);
		}
	},

	repaintChildIndent: function() {
		if (!this.node.treegrid.columnModel.hasVisibleColumns()) {
			return;
		}
		this.updateExpandIcon();
		var cs = this.node.childNodes;
		if (!cs || (cs.length == 0)) {
			return;
		}
		var childNode;
		delete this.childIndent;
		var indent = this.getChildIndent();
		var hasIndent = false;
		for (var i = 0, len = cs.length; i < len; i++) {
			var childNode = cs[i];
			if (childNode.rendered){
				childNode.ui.deleteChildIndent();
				if (indent.length > 0){
					childNode.ui.insertChildIndent(indent);
					if (childNode.childNodes) {
						childNode.ui.repaintChildIndent();
					}
				}
			}	
		}
	},

	getChildIndent: function() {
		if (!this.childIndent) {
			var buf = [];
			var node = this.node;
			while (node) {
				if (!node.isRoot) {
					if (node.isLast()) {
						buf.unshift('<td class="x-tree-node-indent"></td>');
					} else {
						buf.unshift('<td class="x-tree-node-indent x-tree-elbow-linestyle"></td>');
					}
				}	
				node = node.parentNode;
			}
			this.childIndent = buf;
		}
		return this.childIndent;
	},
	
	insertChildIndent: function(indent){
		for (var i=indent.length-1; i>=0; i--){
			Ext.DomHelper.insertFirst(this.firstCell, indent[i]);
		}
	},
	
	deleteChildIndent: function(){
		var indentStyle = '.x-tree-node-indent';
		var indentNode = this.firstCell.child(indentStyle);
		while(indentNode){
			indentNode.remove();
			indentNode = this.firstCell.child(indentStyle);
		}
	},

	clearCellIcons: function(cell){
		var iconCls = ".x-treegrid-cell-icon";
		var cellIcon = Ext.get(cell).child(iconCls);
		while (cellIcon) {
			cellIcon.dom.style.backgroundImage = "";
			cellIcon = cellIcon.next(iconCls);
		}	
	},

	destroy: function() {
		delete this.elNode;
		delete this.ctNode;
		delete this.indentNode;
		delete this.ecNode;
		delete this.checkbox;
		delete this.anchor;
		delete this.textNode;
		Ext.removeNode(this.ctNode);
	}
};

Ext.treegrid.RootTreeNodeUI = Ext.extend(Ext.treegrid.TreeNodeUI, {

	collapse: Ext.emptyFn,
	expand: Ext.emptyFn,

	render: function() {
		if (!this.rendered) {
			var targetNode = this.node.treegrid.innerCt.dom;
			this.node.expanded = true;
			this.wrap = this.ctNode = targetNode;
		}
	},

	renderEmptyRowSpace: function(){
		var emptySpaceNode = this.getEmptySpaceNode();
		if (emptySpaceNode){
			this.deleteEmptySpaceNode();
		}
		var rowTemplate = new Ext.Template(
					'<div ext:tree-node-id="{rowID}" class="x-treegrid-row {emptySpaceClass}">',
					'<table class="x-treegrid-row-table" border="0" cellspacing="0" cellpadding="0" style="{style}">',
						'<tbody>',
							'<tr>{cells}</tr>',
						'</tbody>',
					'</table>',
				'</div>'
				);
		var node = this.node;
		var treegrid = node.treegrid;
		var cols = treegrid.getColumns();
		var colModel = treegrid.getColumnModel();
		var cell = new Object();
		var buf = new Array();
		var cellTemplate;
		for (var i = 0, isFirstCell = true, len = cols.length; i < len; i++) {
			c = cols[i];
			if (!c.isVisible) {
				continue;
			}
			cellTemplate = new Ext.Template(
				'<td class="x-treegrid-col x-treegrid-cell x-treegrid-cell-{name} {lastColumn}" style="{style}" tabIndex="-1" {cellAttr}>',
					'<div class="x-treegrid-cell-inner x-treegrid-anchor" {attr}>',
						'<div class="value">{value}</div>',
					'</div>',
				'</td>'
			);
			cell.name = c.name;
			cell.value = "";
			cell.lastColumn = colModel.isLastVisibleColumn(i) ? "last-column" : "";
			cell.style = treegrid.view.getColumnStyle(i);
			buf.push(cellTemplate.apply(cell));
			var row = new Object();
			row.rowID = "emptySpace";
			row.emptySpaceClass = treegrid.view.emptySpaceClass;
			row.style = "width:" + treegrid.view.getTotalWidth();
			row.cells = buf.join("");
			var rowNode = rowTemplate.apply(row);
		}
		var targetNode = this.ctNode;
		this.wrap = Ext.DomHelper.insertHtml("beforeEnd", targetNode, rowNode || '');
	},

	deleteEmptySpaceNode: function(){
		var emptySpaceNode = this.getEmptySpaceNode();
		this.ctNode.removeChild(emptySpaceNode);
	},

	getEmptySpaceNode: function(){
		var view = this.node.treegrid.view;
		var node = Ext.get(this.ctNode).child("div."+view.emptySpaceClass);
		if (node){
			return node.dom;
		} else {
			return null;
		}
	}

});

Ext.data.Node = function(attributes) {
	this.attributes = attributes || {};
	this.leaf = this.attributes.leaf;
	this.id = this.attributes.id;

	if (!this.id) {
		this.id = Ext.id(null, "ynode-");
		this.attributes.id = this.id;
	}

	this.childNodes = [];
	if (!this.childNodes.indexOf) {
		this.childNodes.indexOf = function(o) {
			for (var i = 0, len = this.length; i < len; i++) {
				if (this[i] == o) return i;
			}
			return -1;
		};
	}

	this.parentNode = null;
	this.firstChild = null;
	this.lastChild = null;
	this.previousSibling = null;
	this.nextSibling = null;

	this.addEvents({
		"append": true,
		"remove": true,
		"move": true,
		"insert": true,
		"beforeappend": true,
		"beforeremove": true,
		"beforemove": true,
		"beforeinsert": true
	});
	this.listeners = this.attributes.listeners;
	Ext.data.Node.superclass.constructor.call(this);
};

Ext.extend(Ext.data.Node, Ext.util.Observable, {

	fireEvent: function(evtName) {
		if (Ext.data.Node.superclass.fireEvent.apply(this, arguments) === false) {
			return false;
		}

		var ot = this.getTreeGrid();
		if (ot) {
			if (ot.proxyNodeEvent.apply(ot, arguments) === false) {
				return false;
			}
		}
		return true;
	},

	isLeaf: function() {
		return this.leaf === true;
	},

	setFirstChild: function(node) {
		this.firstChild = node;
	},

	setLastChild: function(node) {
		this.lastChild = node;
	},

	isLast: function() {
		return (!this.parentNode ? true : this.parentNode.lastChild == this);
	},

	isFirst: function() {
		return (!this.parentNode ? true : this.parentNode.firstChild == this);
	},

	hasChildNodes: function() {
		if (this.treegrid.dataSource.isDynamicDataLoading()) {
			return !this.isLeaf();
		} else {
			return (this.childNodes.length > 0);
		}
	},

	isExpandable: function() {
		return (this.expandable != false) && (this.hasChildNodes());
	},

	appendChild: function(node) {
		var multi = false;
		if (Ext.isArray(node)) {
			multi = node;
		} else if (arguments.length > 1) {
			multi = arguments;
		}

		if (multi) {
			for (var i = 0, len = multi.length; i < len; i++) {
				this.appendChild(multi[i]);
			}
		} else {
			if (this.fireEvent("beforeappend", this.treegrid, this, node) === false) {
				return false;
			}
			var index = this.childNodes.length;
			var oldParent = node.parentNode;
			if (oldParent) {
				if (node.fireEvent("beforemove", node.getTreeGrid(), node, oldParent, this, index) === false) {
					return false;
				}
				oldParent.removeChild(node, false);
			}
			index = this.childNodes.length;
			if (index == 0) {
				this.setFirstChild(node);
			}
			this.childNodes.push(node);
			node.parentNode = this;
			var ps = this.childNodes[index - 1];
			if (ps) {
				node.previousSibling = ps;
				ps.nextSibling = node;
			} else {
				node.previousSibling = null;
			}
			node.nextSibling = null;
			this.setLastChild(node);
			node.setTreeGrid(this.getTreeGrid());
			this.fireEvent("append", this.treegrid, this, node, index);
			if (oldParent) {
				node.fireEvent("move", this.treegrid, node, oldParent, this, index);
			}
			return node;
		}
	},

	removeChild: function(node) {
		var index = this.childNodes.indexOf(node);
		if (index == -1) {
			return false;
		}
		if (this.fireEvent("beforeremove", this.treegrid, this, node) === false) {
			return false;
		}
		this.childNodes.splice(index, 1);
		if (node.previousSibling) {
			node.previousSibling.nextSibling = node.nextSibling;
		}
		if (node.nextSibling) {
			node.nextSibling.previousSibling = node.previousSibling;
		}
		if (this.firstChild == node) {
			this.setFirstChild(node.nextSibling);
		}
		if (this.lastChild == node) {
			this.setLastChild(node.previousSibling);
		}
		node.setTreeGrid(null);
		node.parentNode = null;
		node.previousSibling = null;
		node.nextSibling = null;
		this.fireEvent("remove", this.treegrid, this, node);
		return node;
	},

	insertBefore: function(node, refNode) {
		if (!refNode) {
			return this.appendChild(node);
		}

		if (node == refNode) {
			return false;
		}

		if (this.fireEvent("beforeinsert", this.treegrid, this, node, refNode) === false) {
			return false;
		}
		var index = this.childNodes.indexOf(refNode);
		var oldParent = node.parentNode;
		var refIndex = index;

		if (oldParent == this && this.childNodes.indexOf(node) < index) {
			refIndex--;
		}

		if (oldParent) {
			if (node.fireEvent("beforemove", node.getTreeGrid(), node, oldParent, this, index, refNode) === false) {
				return false;
			}
			oldParent.removeChild(node, false);
		}
		if (refIndex == 0) {
			this.setFirstChild(node);
		}
		this.childNodes.splice(refIndex, 0, node);
		node.parentNode = this;
		var ps = this.childNodes[refIndex - 1];
		if (ps) {
			node.previousSibling = ps;
			ps.nextSibling = node;
		} else {
			node.previousSibling = null;
		}
		node.nextSibling = refNode;
		refNode.previousSibling = node;
		node.setTreeGrid(this.getTreeGrid());
		this.fireEvent("insert", this.treegrid, this, node, refNode);
		if (oldParent) {
			node.fireEvent("move", this.treegrid, node, oldParent, this, refIndex, refNode);
		}
		return node;
	},

	remove: function() {
		this.parentNode.removeChild(this);
		return this;
	},

	item: function(index) {
		return this.childNodes[index];
	},

	replaceChild: function(newChild, oldChild) {
		this.insertBefore(newChild, oldChild);
		this.removeChild(oldChild);
		return oldChild;
	},

	indexOf: function(child) {
		return this.childNodes.indexOf(child);
	},

	getTreeGrid: function() {
		if (!this.treegrid) {
			var p = this;
			while (p) {
				if (p.treegrid) {
					this.treegrid = p.treegrid;
					break;
				}
				p = p.parentNode;
			}
		}
		return this.treegrid;
	},

	getDepth: function() {
		var depth = 0;
		var p = this;
		while (p.parentNode) {
			++depth;
			p = p.parentNode;
		}
		return depth;
	},

	setTreeGrid: function(treegrid) {
		if (treegrid != this.treegrid) {
			if (this.treegrid) {
				this.treegrid.unregisterNode(this);
			}
			this.treegrid = treegrid;
			var cs = this.childNodes;
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].setTreeGrid(treegrid);
			}
			if (treegrid) {
				treegrid.registerNode(this);
			}
		}
	},

	getPath: function(attr) {
		attr = attr || "id";
		var p = this.parentNode;
		var b = [this.attributes[attr]];
		while (p) {
			b.unshift(p.attributes[attr]);
			p = p.parentNode;
		}
		var sep = this.getTreeGrid().pathSeparator;
		return sep + b.join(sep);
	},

	bubble: function(fn, scope, args) {
		var p = this;
		while (p) {
			if (fn.apply(scope || p, args || [p]) === false) {
				break;
			}
			p = p.parentNode;
		}
	},

	cascade: function(fn, scope, args) {
		if (fn.apply(scope || this, args || [this]) !== false) {
			var cs = this.childNodes;
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].cascade(fn, scope, args);
			}
		}
	},

	eachChild: function(fn, scope, args) {
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			if (fn.apply(scope || this, args || [cs[i]]) === false) {
				break;
			}
		}
	},

	findChild: function(attribute, value) {
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			if (cs[i].attributes[attribute] == value) {
				return cs[i];
			}
		}
		return null;
	},

	findChildBy: function(fn, scope) {
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			if (fn.call(scope || cs[i], cs[i]) === true) {
				return cs[i];
			}
		}
		return null;
	},

	sort: function(fn, scope) {
		var cs = this.childNodes;
		var len = cs.length;
		if (len > 0) {
			var sortFn = scope ? function() { fn.apply(scope, arguments); } : fn;
			cs.sort(sortFn);
			for (var i = 0; i < len; i++) {
				var n = cs[i];
				n.previousSibling = cs[i - 1];
				n.nextSibling = cs[i + 1];
				if (i == 0) {
					this.setFirstChild(n);
				}
				if (i == len - 1) {
					this.setLastChild(n);
				}
			}
		}
	},

	contains: function(node) {
		return node.isAncestor(this);
	},

	isAncestor: function(node) {
		var p = this.parentNode;
		while (p) {
			if (p == node) {
				return true;
			}
			p = p.parentNode;
		}
		return false;
	},

	toString: function() {
		return "[Node" + (this.id ? " " + this.id : "") + "]";
	}
});

Ext.treegrid.TreeNode = function(attributes) {
	attributes = attributes || {};
	if (typeof attributes == "string") {
		attributes = { text: attributes };
	}
	this.childrenRendered = false;
	this.rendered = false;
	Ext.treegrid.TreeNode.superclass.constructor.call(this, attributes);
	delete attributes.id;
	this.expanded = attributes.expanded === true;
	this.isTarget = attributes.isTarget !== false;
	this.draggable = attributes.draggable !== false && attributes.allowDrag !== false;
	this.allowChildren = attributes.allowChildren !== false && attributes.allowDrop !== false;
	this.text = attributes.text;
	this.disabled = attributes.disabled === true;

	this.addEvents(
		"textchange",
		"beforeexpand",
		"beforecollapse",
		"expand",
		"disabledchange",
		"collapse",
		"beforeclick",
		"click",
		"checkchange",
		"dblclick",
		"contextmenu",
		"beforechildrenrendered"
	);

	var uiClass = this.attributes.uiProvider || this.defaultUI || Terrasoft.treegrid.ColumnNodeUI;

	this.ui = new uiClass(this);
};

Ext.extend(Ext.treegrid.TreeNode, Ext.data.Node, {
	preventHScroll: true,

	isExpanded: function() {
		return this.expanded;
	},

	getUI: function() {
		return this.ui;
	},

	appendChild: function(n) {
		if (!n.render && !Ext.isArray(n)) {
			n = this.getTreeGrid().createNode(n);
		}
		var node = Ext.treegrid.TreeNode.superclass.appendChild.call(this, n);
		if (node && this.childrenRendered) {
			node.render();
			var previousSibling = node.previousSibling;
			if (previousSibling && previousSibling.rendered){
				previousSibling.ui.repaintChildIndent();
			}
		}
		if (this.rendered){
			this.showChildrenContainer();
		}
		if (this.childNodes.length == 1) {
			this.ui.updateExpandIcon();
		}
		return node;
	},

	removeChild: function(node, changePosition) {
		var selectionModel = this.treegrid.getSelectionModel();
		selectionModel.unselect(node);
		if (changePosition != false) {
			var activeNode = selectionModel.activeNode;
			if ((node.rendered) && (activeNode) && (activeNode == node))  {
				if ((activeNode) && (activeNode == node)){
					if (!selectionModel.selectNextSibling()){
						selectionModel.selectPrevious();
					}
				}
			}
		}
		var previousSibling = node.previousSibling;
		var isLast = node.isLast();
		Ext.treegrid.TreeNode.superclass.removeChild.apply(this, arguments);
		if (node.rendered) {
			node.ui.remove();
			if (isLast && previousSibling){
				previousSibling.ui.repaintChildIndent();
			}
		}
		var treegrid = this.getTreeGrid();
		if (treegrid.isTreeMode() && (this.childNodes.length == 0)) {
			this.leaf = true;
			this.collapse(false, false);
		} else {
			this.ui.updateExpandIcon();
		}
		if (this.rendered){
		this.showChildrenContainer();
		}
		return node;
	},

	insertBefore: function(node, refNode) {
		if (!node.render) {
			node = this.getTreeGrid().createNode(node);
		}
		var newNode = Ext.treegrid.TreeNode.superclass.insertBefore.apply(this, arguments);
		if (newNode && refNode && this.childrenRendered) {
			newNode.render();
			var previousSibling = node.previousSibling;
			if (previousSibling && previousSibling.rendered){
				previousSibling.ui.updateExpandIcon();
			}	
		}
		if (this.ui.rendered) {
			this.showChildrenContainer();
		}
		return newNode;
	},

	showChildrenContainer: function() {
		var ctNode = this.ui.ctNode;
		var display = "none";
		if (((this.childNodes.length > 0) && this.expanded) || (this.isRoot)) {
			display = "";
		}
		ctNode.style.display = display;
	},

	setEditedValue: function(text, col) {
		text = text ? Ext.util.Format.htmlEncode(text) : '';
		var oldText = this.text;
		this.text = text;
		this.attributes.text = text;
		if (this.rendered) {
			this.ui.onValueChange(text, col);
		}
		this.fireEvent("textchange", this, text, oldText);
	},

	select: function() {
		this.getTreeGrid().getSelectionModel().select(this);
	},

	unselect: function() {
		this.getTreeGrid().getSelectionModel().unselect(this);
	},

	isSelected: function() {
		return this.getTreeGrid().getSelectionModel().isSelected(this);
	},

	expand: function(deep, anim, callback) {
		if (!this.expanded) {
			var treegrid = this.getTreeGrid();
			if (this.fireEvent("beforeexpand", this, deep, anim) === false) {
				return;
			}
			if (!this.childrenRendered) {
				this.renderChildren();
			}
			this.expanded = true;
			if ((treegrid.animate && anim !== false) || anim) {
				this.ui.animExpand(function() {
					this.fireEvent("expand", this);
					if (typeof callback == "function") {
						callback(this);
					}
					if (deep === true) {
						this.expandChildNodes(true);
					}
					treegrid.view.processRows();
				} .createDelegate(this));
				return;
			} else {
				this.ui.expand();
				this.fireEvent("expand", this);
				if (typeof callback == "function") {
					callback(this);
				}
				treegrid.view.processRows();
			}
			treegrid.view.updateScroll(); 
		} else {
			if (typeof callback == "function") {
				callback(this);
			}
		}
		if (deep === true) {
			this.expandChildNodes(true);
		}
	},
	
	collapse: function(deep, anim) {
		var treegrid = this.getTreeGrid();
		if (this.expanded) {
			if (this.fireEvent("beforecollapse", this, deep, anim) === false) {
				return;
			}
			this.expanded = false;
			if ((treegrid.animate && anim !== false) || anim) {
				this.ui.animCollapse(function() {
					this.fireEvent("collapse", this);
					if (deep === true) {
						this.collapseChildNodes(true);
					}
					treegrid.view.processRows();
				} .createDelegate(this));
				return;
			} else {
				this.ui.collapse();
				this.fireEvent("collapse", this);
				treegrid.view.processRows();
			}
			treegrid.view.updateScroll();
		}
		if (deep === true) {
			var cs = this.childNodes;
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].collapse(true, false);
			}
		}
	},

	delayedExpand: function(delay) {
		if (!this.expandProcId) {
			this.expandProcId = this.expand.defer(delay, this);
		}
	},

	cancelExpand: function() {
		if (this.expandProcId) {
			clearTimeout(this.expandProcId);
		}
		this.expandProcId = false;
	},

	toggle: function() {
		if (this.expanded) {
			this.collapse();
		} else {
			this.expand();
		}
	},

	expandChildNodes: function(deep) {
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i].expand(deep);
		}
	},

	collapseChildNodes: function(deep) {
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i].collapse(deep);
		}
	},

	disable: function() {
		this.disabled = true;
		this.unselect();
		if (this.rendered && this.ui.onDisableChange) {
			this.ui.onDisableChange(this, true);
		}
		this.fireEvent("disabledchange", this, true);
	},

	enable: function() {
		this.disabled = false;
		if (this.rendered && this.ui.onDisableChange) {
			this.ui.onDisableChange(this, false);
		}
		this.fireEvent("disabledchange", this, false);
	},

	renderChildren: function(suppressEvent) {
		if (suppressEvent !== false) {
			this.fireEvent("beforechildrenrendered", this);
		}
		var cs = this.childNodes;
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i].render(true);
		}
		this.childrenRendered = true;
	},

	removeChildren: function() {
		var treegrid = this.treegrid;
		treegrid.suspendEvents();
		try {
	 		while (this.firstChild) {
				this.removeChild(this.firstChild, false);
			}
		} finally {
			treegrid.resumeEvents();
		}
		var selModel = treegrid.getSelectionModel();
		selModel.activeNode = null;
	},

	sort: function(fn, scope) {
		Ext.treegrid.TreeNode.superclass.sort.apply(this, arguments);
		if (this.childrenRendered) {
			var cs = this.childNodes;
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].render(null, true);
			}
		}
	},

	render: function(bulkRender) {
		this.ui.render(null, bulkRender);
		if (!this.rendered) {
			this.getTreeGrid().registerNode(this);
			this.rendered = true;
			if (this.expanded) {
				this.expanded = false;
				this.expand(false, false);
			}
		}
	},

	rerender: function(expand) {
		this.childrenRendered = false;
		this.ui.rerender();
		this.expanded = false;
		var cs = this.childNodes;
		if (cs) {
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].rendered = false;
			}
			for (var i = 0, len = cs.length; i < len; i++) {
				cs[i].rerender(false);
			}
		}
		if (expand) {
			this.expand(true);
		}
	},

	beginUpdate: function() {
		this.childrenRendered = false;
	},

	endUpdate: function() {
		if (this.expanded && this.rendered) {
			this.renderChildren();
		}
	},

	destroy: function() {
		if (this.childNodes) {
			for (var i = 0, l = this.childNodes.length; i < l; i++) {
				this.childNodes[i].destroy();
			}
			this.childNodes = null;
		}
		if (this.ui.destroy) {
			this.ui.destroy();
		}
	},
	
	isLast: function() {
		return (!this.parentNode || this.parentNode.isRoot ? true : this.parentNode.lastChild == this);
	},
	
	isElderSibling: function(siblingNode) {
		var previousSibling = this.previousSibling;
		return previousSibling ? 
			((previousSibling == siblingNode) ? true : previousSibling.isElderSibling(siblingNode)) : false;
	},
	
	setExpandable: function(isExpandable) {
		this.expandable = isExpandable;
		var treegrid = this.treegrid;
		var nodeConfig = treegrid.configs;
		var nodeId = this.id;
		if (nodeConfig && nodeConfig[nodeId] && (nodeConfig[nodeId].expandable !== isExpandable)) {
			nodeConfig[nodeId].expandable = isExpandable;
		}
	}
});

Ext.treegrid.AsyncTreeNode = function(config) {
	this.loaded = config && config.loaded === true;
	this.loading = false;
	Ext.treegrid.AsyncTreeNode.superclass.constructor.apply(this, arguments);

	this.addEvents('beforeload', 'load');
};

Ext.extend(Ext.treegrid.AsyncTreeNode, Ext.treegrid.TreeNode, {

	expand: function(deep, anim, callback) {
		if (this.loading) {
			var timer;
			var f = function() {
				if (!this.loading) {
					clearInterval(timer);
					this.expand(deep, anim, callback);
				}
			} .createDelegate(this);
			timer = setInterval(f, 200);
			return;
		}
		if (!this.loaded) {
			if (this.fireEvent("beforeload", this) === false) {
				return;
			}
			this.loading = true;
			var selectDirection = "";
			var pageableNodeId = "";
			if (!this.isRoot) {
				selectDirection = "Current";
			} else {
				selectDirection = this.selectDirection;
				pageableNodeId = this.pageableNodeId;
			}
			var treegrid = this.treegrid;
			var dataSource = treegrid.dataSource;
			var treegrid = this.getTreeGrid();
			treegrid.dataSource.load({
				alreadyContainsRows: true,
				filteredColumnName: dataSource.getHierarchicalColumnName(),
				filterValue: dataSource.getValue(this.id, dataSource.structure.primaryColumnName),
				pageableDirection: selectDirection,
				pageableRowId: pageableNodeId,
				add: true,
				attribute: {
					node: this,
					callback: this.loadChildrenComplete.createDelegate(this)
				}
			});
			return;
		}
		Ext.treegrid.AsyncTreeNode.superclass.expand.call(this, deep, anim, callback);
	},

	expandAllParents: function() {
		if (!this.isRoot) {
			var parentNode = this.parentNode;
			if (parentNode.isRoot && !parentNode.rendered) {
				parentNode.render();
			}
			parentNode.expandAllParents();
		}
		if (!this.expanded) {
			this.expand();
		}
	},

	addLoadedRecords: function(records, dataSource, cfg) {
		var treegrid = this.getTreeGrid();
		if (dataSource.getHierarchicalColumnName()) {
			var nodes = this.recordsToTreeNodes(records, dataSource);
			this.addTreeNodes(nodes, cfg);
		} else {
			var positions = (cfg && cfg.positions) ? cfg.positions : null;
			this.addRecords(records, dataSource, positions);
		}
		//Пока нет потребности выполнять этот рендеринг, т.к. он выполняется дальше другим методом
		//this.endUpdate();
	},

	createUIProvider: function() {
		return Terrasoft.ColumnNodeUI;
	},

	insertNode: function(node, place) {
		var insertPosition = place.position;
		var parentId = place.targetRowPrimaryColumnValue;
		var treegrid = this.getTreeGrid();
		var targetRow = parentId ? treegrid.getNodeById(parentId) : treegrid.root;
		var updateNode = (insertPosition == "Append") ? targetRow : targetRow.parentNode;
		treegrid.suspendEvents();
		try {
			if (!updateNode.rendered) {
				updateNode.render();
			}
			updateNode.loaded = true;
			treegrid.appendChildNode(node, updateNode, true, insertPosition, targetRow);
		} finally {
			treegrid.resumeEvents();
		}
	},

	addRecords: function(records, dataSource, positions) {
		for (var i = 0, len = records.length; i < len; i++) {
			var record = records[i];
			var recordId = record[dataSource.structure.primaryColumnName];
			var n = this.createNode({
				id: recordId
			});
			var treegrid = this.getTreeGrid();
			if (positions && positions[recordId] && n.rendered) {
				this.insertNode(n, positions[recordId]);
			} else {
				this.appendChild(n);
			}
		}
	},

	addTreeNodes: function(nodes, cfg) {
		var treegrid = this.getTreeGrid();
		for (var i = 0, len = nodes.keys.length; i < len; i++) {
			var recordId = nodes.keys[i];
			var n = this.createNode({
				id: recordId
			});
			var item = nodes.items[i];
			var parentNodeId = item.parentNodeId;
			n.parentId = parentNodeId;
			var parentNode = treegrid.getNodeById(parentNodeId) || treegrid.root;
			if (cfg && cfg.positions && cfg.positions[recordId] && n.rendered) {
				this.insertNode(n, cfg.positions[recordId]);
			} else {
				parentNode.loaded = true;
				parentNode.setExpandable(true);
				parentNode.appendChild(n);
			}
			var childNodes = item.childNodes;
			if (childNodes) {
				this.addTreeNodes(childNodes, cfg);
			}
			if (treegrid.configs && treegrid.configs[parentNodeId] && treegrid.configs[parentNodeId].expandOnLoad) {
				parentNode.expandAllParents();
				delete treegrid.configs[parentNodeId].expandOnLoad;
			}
		}
		var isRoot = treegrid.getNodeById(parentNodeId) ? false : true;
		if (cfg && cfg.hasNextPage && cfg.hasNextPage[parentNodeId]) {
			if (isRoot) {
				treegrid.root.hasNextPage = cfg.hasNextPage[parentNodeId];
			} else { 
				var pagingNode = this.createNode({ isPaging: true });
				parentNode.appendChild(pagingNode);
			}
		} else if (isRoot) {
			treegrid.root.hasNextPage = false;
		}
	},

	recordsToTreeNodes: function(records, dataSource) {
		var nodes = new Ext.util.MixedCollection();
		var primaryColumnName = dataSource.getPrimaryColumnName();
		for (var i = 0, len = records.length; i < len; i++) {
			var record = records[i];
			if (record) {
				var id = record[primaryColumnName];
				nodes.add(id, { processed: false });
			}
		}
		var hierarchicalColumn = dataSource.getColumnByName(dataSource.getHierarchicalColumnName());
		var hierarchicalColumnName = hierarchicalColumn.valueColumnName ? hierarchicalColumn.valueColumnName : hierarchicalColumn.name;
		for (var i = 0, len = records.length; i < len; i++) {
			var record = records[i];
			if (record) {
				var id = record[primaryColumnName];
				var node = nodes.get(id);
				node.parentNodeId = record[hierarchicalColumnName];
				var parentNode = nodes.get(node.parentNodeId);
				if (parentNode) {
					if (!parentNode.childNodes) {
						parentNode.childNodes = new Ext.util.MixedCollection();
					}
					parentNode.childNodes.add(id, node);
					node.processed = true;
				}
			}
		}
		nodes.each(this.deleteProcessedItems, nodes);
		return nodes;
	},

	deleteProcessedItems: function(item) {
		if (item.processed) {
			this.remove(item);
		}
	},

	createNode: function(cfg) {
		var attr = { };
		Ext.apply(attr, this.baseAttrs);
		attr.uiProvider = this.createUIProvider();
		var node = attr.nodeType ? new Terrasoft.TreeGrid.nodeTypes[attr.nodeType](attr) : (attr.leaf ? new Ext.treegrid.TreeNode(attr) : new Ext.treegrid.AsyncTreeNode(attr));
		node.initialConfig = cfg || {};
		Ext.apply(node, node.initialConfig);
		return node;
	},

	addNextPage: function() {
		var treegrid = this.getTreeGrid();
		var dataSource = treegrid.dataSource;
		var pageableRow = this.lastChild.previousSibling;
		treegrid.dataSource.loadNextPage({
			filteredColumnName: dataSource.getHierarchicalColumnName(),
			filterValue: (this.isRoot ? "" : this.id),
			pageableRowId: pageableRow.id,
			add: true,
			attribute: {
				node: this,
				loadNode: this.lastChild,
				callback: this.addingNextPageComplete.createDelegate(this)
			}
		});
	},

	isLoading: function() {
		return this.loading;
	},

	loadChildrenComplete: function() {
		this.loading = false;
		this.loaded = true;
		this.expand();
		this.ui.enableLoadingState(false);
		var treegrid = this.treegrid;
		var view = treegrid.view;
		view.processRows();
		view.updateScroll();
	},

	dataLoadingComplete: function() {
		var treegrid = this.treegrid;
		var view = treegrid.view;
		view.processRows();
		view.updateScroll();
	},

	loadPageComplete: function() {
		var treegrid = this.treegrid;
		var node = this;
		if (!node.rendered) {
			node.loaded = true;
			node.render();
		}
		node.addEmptyRow();
		if (treegrid.footerVisible) {
			pagingToolbar = treegrid.getPagingToolbar();
			if (pagingToolbar && !treegrid.isVirtual() && treegrid.enabled !== false) {
				pagingToolbar.actualizePagingNavigationButtons();
			}
		}
		var view = treegrid.view;
		view.updateHeaders();
		view.processRows();
		treegrid.viewReady = true;
		delete view.lastViewWidth;
		view.updateScroll();
		view.scrollToTop();
		treegrid.hideLoadMask(node);
	},

	addingNextPageComplete: function() {
		if (this.previousPagingNode) {
			this.removeChild(this.previousPagingNode);
			delete this.previousPagingNode;
		}
		var treegrid = this.getTreeGrid();
		treegrid.view.processRows();
		treegrid.view.updateScroll();
		this.loading = false;
		this.loaded = true;
	},

	isLoaded: function() {
		return this.loaded;
	},

	addEmptyRow: function() {
		this.ui.renderEmptyRowSpace();
	},

	hasChildNodes: function() {
		var treegrid = this.treegrid;
		if (!treegrid.isTreeMode()) {
			return false;
		}
		return Ext.treegrid.AsyncTreeNode.superclass.hasChildNodes.call(this);
	},

	onChecked: function(checker, checked, opt) {
		this.checked = checked;
		var treegrid = this.treegrid;
		var nodeId = Ext.util.JSON.encode(this.id);
		treegrid.fireEvent("nodecheck", nodeId, checked);
	},

	getParentId: function(id) {
		var nodes = this.childNodes;
		for (var i = 0, nodeLength = nodes.length; i < nodeLength; i++) {
			var node = nodes[i];
			if (node.id == id)
				return node.parentId;
		}
		return null;
	}
});

Terrasoft.treegrid.ColumnNodeUI = Ext.extend(Ext.treegrid.TreeNodeUI, {
	focus: Ext.emptyFn,
	httpRegExp: '\\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|!:,.;]*[A-Z0-9+&@#/%=~_|]',

	renderElements: function (targetNode, bulkRender) {
		var node = this.node;
		var treegrid = node.getTreeGrid();
		if (!treegrid.columnModel.hasVisibleColumns()) {
			return;
		}
		var nodeTemplate = new Ext.Template(
			'<div ext:tree-node-id="{rowID}" class="x-treegrid-row {treeClass}">',
				'{nodeData}',
				'<div class="x-treegrid-quick-view" style="display:none;"></div>',
				'<ul class="x-tree-node-ct" style="display:none;"></ul>',
			'</div>'
		);

		var rp = {};
		var dataSource = treegrid.dataSource;
		var stripeRows = treegrid.stripeRows;
		var isTreeMode = treegrid.isTreeMode();
		if (isTreeMode) {
			if (node.parentNode.isRoot) {
				rp.treeClass = "x-tree-node-el x-tree-no-lines";
			} else {
				rp.treeClass = "x-tree-node-el x-tree-lines";
			}
			if (node.isPaging) {
				rp.treeClass += " x-tree-node-paging";
			}
		}
		if (Terrasoft.TreeGridSelectionStyle === 1) {
			rp.treeClass += " x-tree-edging";
		}
		rp.rowID = node.id;
		rp.nodeData = this.getDataMarkup();
		var row = nodeTemplate.apply(rp);
		if (bulkRender !== true && node.nextSibling && node.nextSibling.rendered && node.nextSibling.ui.getEl()) {
			this.wrap = Ext.DomHelper.insertHtml("beforeBegin", node.nextSibling.ui.getEl(), row);
		} else {
			this.wrap = Ext.DomHelper.insertHtml("beforeEnd", targetNode, row);
		}
		this.setNodeProperties(node);
	},

	getDataMarkup: function () {
		var dataTemplate = new Ext.Template(
			'<table class="x-treegrid-row-table {mode}" border="0" cellspacing="0" cellpadding="0" style="{style}">',
				'<tbody>',
					'<tr>{cells}</tr>',
				'</tbody>',
			'</table>'
		);
		var node = this.node;
		var treegrid = node.getTreeGrid();
		if (treegrid.configs && treegrid.configs[node.id]) {
			Ext.apply(node, treegrid.configs[node.id]);
		}
		var rows = treegrid.dataSource.rows;
		var columnValues = !node.isPaging ? rows.item(node.id).columns : null;
		var isTreeMode = treegrid.isTreeMode();
		var cols = treegrid.getColumns();
		var indent = node.parentNode.ui.getChildIndent();
		var indentMarkup = indent.join("");
		var hasQuickView = treegrid.hasQuickView();
		var isCheckable = ((node.checkerKind == "checkBox") || (node.checkerKind == "radioButton"));
		var buf = [], cellTemplate, column, colModel = treegrid.getColumnModel(), columnName;
		var treeGridStringList = Ext.StringList('WC.TreeGrid');
		var device = Terrasoft.getDevice();
		for (var i = 0, isFirstCell = true, len = cols.length; i < len; i++) {
			column = cols[i];
			columnName = column.name;
			if (!column.isVisible) {
				continue;
			}
			var columnImageCfg = node.columnIcons ? node.columnIcons[columnName] : null;
			var displayImageOnly = null;
			if (columnImageCfg) {
				displayImageOnly = columnImageCfg.displayImageOnly;
			}
			var p = {};
			p.indentMarkup = indentMarkup;
			p.name = columnName;
			if (node.isPaging) {
				p.value = isFirstCell ? treeGridStringList.getValue('TreeNode.LoadNextPage') : "";
				p.extendClass = "paging";
				p.pagingNode = "paging-node ";
			} else {
				p.value = column.isLookup ? columnValues[column.displayColumnName] : columnValues[columnName];
				p.value = Ext.util.Format.htmlEncode(p.value);
				var customText = this.getCustomText(columnName, node);
				if (column.dataValueType.name == "Boolean" && !displayImageOnly) {
					p.value = p.value || "false";
					if (!customText) {
						p.extendClass = "x-bool-value " + p.value.toLowerCase();
					}
					p.value = "";
				} else if (column.dataValueType.name == "DateTime" && !displayImageOnly) {
					p.value = Ext.util.Format.date(p.value, Ext.util.Format.getDateTimeFormat());
				} else if (column.dataValueType.name == "Date" && !displayImageOnly) {
					p.value = Ext.util.Format.date(p.value, Ext.util.Format.getDateFormat());
				} else if (column.dataValueType.name == "Time" && !displayImageOnly) {
					p.value = Ext.util.Format.date(p.value, Ext.util.Format.getTimeFormat());
				} else {
					if (!displayImageOnly) {
						if (column.dataValueType.isNumeric) {
							var decimalPrecision =
								column.dataValueType.name == 'Integer' ? 0 : column.dataValueType.precision || 2;
							var displayOptions = {
								decimalPrecision: decimalPrecision,
								showTrailingZeros: true
							};
							p.value = Terrasoft.Math.getDisplayValue(p.value, displayOptions);
						}
						p.value =
							(Ext.isEmpty(p.value, false) || (column.dataValueType.name == "Boolean")) ? "" : p.value;
						if (!customText) {
							p.value = this.processValueLinks(column, p.value.toString(), node.links);
						}
						var useProcessValueLinks = true;
						var primaryDisplayColumnName = treegrid.dataSource.structure.primaryDisplayColumnName;
						var isLookup = (column.isLookup ||
							(treegrid.primaryDisplayColumnAsLookup && (columnName == primaryDisplayColumnName)));
					}
					var isColumnAccessDenied =
						Ext.isEmpty(p.value) && treegrid.isColumnAccessDenied(column, columnValues);
					if (isColumnAccessDenied) {
						var accessDeniedMessage = Ext.StringList('WC.TreeGrid').getValue('AccessDenied');
						p.value = Ext.util.Format.htmlEncode(String.format("<{0}>", accessDeniedMessage));
						p.extendClass = "access-denied";
					} else {
						//todo раскоментировать при реализации CR 87340
						//p.extendClass = isLookup ? "lookup" : "";
					}
				}
				if (customText) {
					p.value = useProcessValueLinks === true ?
						this.processValueLinks(column, customText, node.links) : customText;
					useProcessValueLinks = false;
				}
			}
			p.lastColumn = colModel.isLastVisibleColumn(i) ? "last-column" : "";
			p.style = treegrid.view.getColumnStyle(i);
			if (node.boldFont) {
				p.style += "font-weight:bold;";
			}
			p.iconsMarkup = node.isPaging || isColumnAccessDenied ?
				"" : this.getIconsMarkup(column, columnValues, node, isFirstCell);
			p.align = this.getColumnAlign(column);
			p.customClass = node.customClass;
			var cellBackground = this.getCellBackGroundColor(column, node);
			if (cellBackground) {
				p.style += ";background:" + cellBackground;
			}
			cellTemplate = new Ext.Template(
				'<td class="x-treegrid-col x-treegrid-cell x-treegrid-cell-{name} {align} {lastColumn}" style="{style}" tabIndex="-1" {cellAttr}>',
					'<table cellspacing="0" class="x-treegrid-cell-inner x-treegrid-anchor {customClass}" {attr}>',
						'<tr>',
							isFirstCell && indentMarkup ? '{indentMarkup}' : '',
							isFirstCell && isTreeMode ? '<td class="x-tree-icon"><div class="{pagingNode}x-tree-ec-icon"></div></td>' : '',
							isFirstCell && isCheckable && !node.isPaging && !displayImageOnly ? '<td class="x-treegrid-checker"></td>' : '',
							isFirstCell && hasQuickView && !node.isPaging ? '<td class="x-tree-quick-view"><div class="x-tree-cell-arrow"></div></td>' : '',
							'{iconsMarkup}',
							!displayImageOnly || isColumnAccessDenied ? '<td class="x-treegrid-value-td" unselectable="on"><span class="{extendClass} value">{value}</span></td>' : '',
							isFirstCell && device.isMobile ? '<td class="x-tree-cell-mobile"><div class="x-tree-contextmenu-mobile"></div></td>' : '',
						'</tr>',
					'</table>',
				'</td>'
			);
			buf.push(cellTemplate.apply(p));
			isFirstCell = false;
		}
		if (node.columnsBackground) {
			node.columnsBackground = null;
		}
		var nodeData = {};
		nodeData.style = "width:" + treegrid.view.getTotalWidth();
		if (node.background) {
			nodeData.style += ";background:" + node.background;
			node.background = null;
		}
		if (node.color) {
			nodeData.style += ";color:" + node.color;
			node.color = null;
		}
		nodeData.mode = this.isQuickViewVisible ? treegrid.quickView.activeStateCss : "";
		nodeData.cells = buf.join("");
		return dataTemplate.apply(nodeData);
	},

	getIconsMarkup: function (column, columnValues, node, isFirstCell) {
		var columnName = column.name;
		var iconsMarkup = "";
		if (isFirstCell && node.firstColumnIcons) {
			for (iconId in node.firstColumnIcons) {
				var imageCfg = node.firstColumnIcons[iconId];
				iconsMarkup += this.getIconMarkup(imageCfg, iconId, node);
			}
		}
		if (node.imageCfg) {
			iconsMarkup += this.getIconMarkup(node.imageCfg, 'cfg' + columnName, node);
		}
		if (node.columnIcons && node.columnIcons[columnName]) {
			var imageCfg = node.columnIcons[columnName];
			iconsMarkup += this.getIconMarkup(imageCfg, columnName, node);
		}
		return iconsMarkup;
	},

	getIconMarkup: function (imageCfg, iconId, node) {
		var iconClass = 'x-treegrid-cell-icon';
		var iconPosition = imageCfg.imagePosition || '';
		var iconStyle = 'background-image:';
		var iconTemplate = '<td class="{2}" style="{0};" iconId="{1}"></td>';
		var isDbRequest = (imageCfg.source == 'db');
		var imageCfgWrapper = imageCfg;
		var isControlImage = Ext.isEmpty(imageCfg.resourceName) && !isDbRequest;
		var treegrid = node.getTreeGrid();
		if (isControlImage) {
			imageCfgWrapper = treegrid.getImageConfigWrapper(imageCfg);
		} else {
			imageCfgWrapper.resourceManager = (imageCfg.resourceManager || treegrid.imageList);
		}
		var imageUrl = Ext.ImageUrlHelper.getImageUrl(imageCfgWrapper);
		iconStyle += imageUrl + ';';
		if (iconPosition) {
			var tdMarkup = '<td>&nbsp;</td>';
			if (iconPosition === 'center') {
				iconTemplate = tdMarkup + iconTemplate;
				iconStyle += 'background-position:' + iconPosition + ';';
			}
			iconTemplate += tdMarkup;
		}
		if (Ext.decode(imageCfgWrapper.interactive)) {
			iconClass += ' interactive';
		}
		return String.format(iconTemplate, iconStyle, iconId, iconClass);
	},

	getColumnAlign: function (column) {
		var align = "";
		switch (column.dataValueType.name) {
			case "Integer":
			case 'Float1':
			case 'Float2':
			case 'Float3':
			case 'Float4':
			case "Money":
				align = "align-right";
				break;
			case "Boolean":
				align = "align-center";
				break;
		}
		return align;
	},

	getCellBackGroundColor: function (column, node) {
		var cellbackground = '';
		if (node.columnsBackground) {
			cellbackground = node.columnsBackground[column.name] || '';
		}
		return cellbackground;
	},

	getCustomText: function (columnName, node) {
		var columnsCustomText = node.columnsCustomText;
		return columnsCustomText ? columnsCustomText[columnName] : null;
	},

	rerenderData: function () {
		var dataMarkup = this.getDataMarkup(dataMarkup);
		var parentNode = this.elNode.parentNode;
		var treeIconClass;
		if (this.ecNode) {
			treeIconClass = this.ecNode.className;
		}
		parentNode.removeChild(this.elNode);
		Ext.DomHelper.insertFirst(parentNode, dataMarkup);
		this.setNodeProperties();
		if (this.ecNode) {
			this.ecNode.className = treeIconClass;
		}
		if (this.node.isSelected()) {
			this.onSelectedChange(true);
		}
	},

	processValueLinks: function (column, sourceText, links) {
		var linkText, re;
		sourceText = this.replaceHypertextLinks(sourceText);
		if (links) {
			sourceText = Ext.Link.applyLinks(sourceText, links);
		}
		return sourceText;
	},

	createValueLinkHTML: function (linkId, linkText) {
		var template = '<a class="x-treegrid-value-link" linkId="{0}">{1}</a>';
		return String.format(template, linkId, linkText);
	},

	replaceHttpLinks: function (sourceText) {
		var re = new RegExp(this.httpRegExp, 'ig');
		var result = sourceText.replace(re, '<a href="$&" class="href-link" target="_blank" title="$&">$&</a>');
		return result;
	},

	replaceHypertextLinks: function(sourceText) {
		sourceText = this.replaceHttpLinks(sourceText);
		return sourceText;
	},

	setNodeProperties: function (node) {
		this.elNode = this.wrap.childNodes[0];
		this.prevNode = this.wrap.childNodes[1];
		this.ctNode = this.wrap.childNodes[2];
		var firstCell = Ext.get(this.elNode.firstChild.firstChild.firstChild);
		if (firstCell) {
			this.firstCell = firstCell.child('tr');
			var treeIcon = firstCell.child('div.x-tree-ec-icon');
			if (treeIcon) {
				this.ecNode = treeIcon.dom.parentNode;
			}
			var checker = firstCell.child('.x-treegrid-checker');
			if (checker) {
				this.initializeChecker(node, checker);
			}
			this.anchor = this.textNode = firstCell.dom;
		}
	},

	initializeChecker: function (node, checkerNode) {
		node.enabled = (node.enabled !== false);
		var checker;
		switch (node.checkerKind) {
			case "checkBox":
				checker = new Terrasoft.treegrid.TreeNodeCheckBox({
					checked: node.checked,
					enabled: node.enabled,
					renderTo: checkerNode
				});
				break;
			case "radioButton":
				var groupName = node.parentNode.id;
				checker = new Terrasoft.treegrid.TreeNodeRadio({
					checked: node.checked,
					enabled: node.enabled,
					renderTo: checkerNode,
					name: groupName
				});
				break;
		}
		node.checker = checker;
		node.checker.on('check', node.onChecked, node);
	}
});

Terrasoft.treegrid.QuickView = function(config) {
	Ext.apply(this, config);
	var dataSource = this.treegrid.dataSource;
	dataSource.on("quickviewload", this.onDataSourceQuickViewLoad, this);
	dataSource.on("beforeloadquickview", this.onDataSourceBeforeLoadQuickView, this);
	dataSource.on("quickviewloadexception", this.onDataSourceQuickViewLoadException, this);
};

Ext.extend(Terrasoft.treegrid.QuickView, Ext.util.Observable, {
	activeStateCss: "preview-mode",
	loadingStateCss: "data-loading",

	render: function (targetRow, data) {
		this.template = new Ext.Template(
					'<table width="100%" border="0" cellspacing="0" cellpadding="0">',
						'<tr>',
							'{indentMarkup}',
							'<td class="x-treegrid-quick-view-data">',
								'<div class="x-treegrid-quick-view-border">',
									'<table class="x-treegrid-quick-view-table">',
										'{rows}',
									'</table>',
								'<div>',
							'</td>',
						'</tr>',
					'</table>'
			);
		this.rowTemplate = new Ext.Template(
							'<tr>{leftColumn}{rightColumn}</tr>'
			);
		this.fieldTemplate = new Ext.Template(
					'<td class="title">{title}</td>',
					'<td class="{border} {extendedClass} value">{value}</td>'
			);
		this.textRowTemplate = new Ext.Template(
					'<tr><td class="value">{text}</td></tr>'
			);
		var fieldHTML, rowHTML;
		var row = new Object();
		var rows = new Array();
		if (this.mode == 'Columns') {
			var complete = false;
			var columns = this.treegrid.dataSource.structure.quickViewColumns;
			var column, isLastColumn;
			for (var i = 0, count = columns.length, odd = true; i < count; i++) {
				column = columns[i];
				var valueType = column.dataValueType.name;
				var field = new Object;
				field.value = (column.isLookup) ? data[0][column.displayColumnName] : data[0][column.name];
				if (valueType == "Boolean") {
					field.value = field.value === true ? Ext.StringList('WC.TreeGrid').getValue('TrueCaption') :
						Ext.StringList('WC.TreeGrid').getValue('FalseCaption');
				} else if (valueType == "DateTime") {
					field.value = Ext.util.Format.date(field.value, Ext.util.Format.getDateTimeFormat());
				} else if (valueType == "Date") {
					field.value = Ext.util.Format.date(field.value, Ext.util.Format.getDateFormat());
				} else if (valueType == "Time") {
					field.value = Ext.util.Format.date(field.value, Ext.util.Format.getTimeFormat());
				}
				if (!Ext.isEmpty(field.value)) { 
					field.value = targetRow.replaceHypertextLinks(field.value.toString());
				}
				field.title = column.caption;
				if (Ext.isEmpty(field.value) && this.treegrid.isColumnAccessDenied(column, data[0])) {
					field.value = Ext.StringList('WC.TreeGrid').getValue('AccessDenied');
					field.extendedClass = "access-denied";
				} else {
					//todo раскоментировать при реализации CR 87340
					//field.extendedClass = column.isLookup ? "lookup" : "";
				}
				field.border = (odd) ? "right-border" : "";
				fieldHTML = this.fieldTemplate.apply(field);
				if (row.leftColumn) {
					row.rightColumn = fieldHTML;
					complete = true;
				} else {
					row.leftColumn = fieldHTML;
				}
				isLastColumn = (i == (count - 1));
				if (complete || (isLastColumn)) {
					rowHTML = this.rowTemplate.apply(row);
					rows.push(rowHTML);
					row.leftColumn = "";
					row.rightColumn = "";
					complete = false;
				}
				odd = !odd;
			}
		} else {
			var firstColumn = this.dataSource.structure.quickViewColumns[0];
			row.text = data[0][firstColumn.displayColumnName];
			rows.push(this.textRowTemplate.apply(row));
		}
		var preview = new Object();
		var indent = targetRow.getChildIndent();
		if (indent.length > 0) {
			preview.indentMarkup = indent.join("");
		}
		preview.rows = rows.join("");
		previewHTML = this.template.apply(preview);
		this.wrap = Ext.DomHelper.overwrite(targetRow.prevNode, previewHTML);
	},
	
	show: function (row) {
		this.getData(row);
	},
	
	hide: function (row) {
		prevNode = row.prevNode;
		prevNode.innerHTML = "";
		prevNode.style.display = "none";
		row.isQuickViewVisible = false;
		this.setActiveState(row, row.isQuickViewVisible);
	},

	getData: function (row) {
		this.treegrid.dataSource.loadQuickView({
			primaryColumnValue: row.node.id,
			attribute: {
				row: row
			}
		});
		this.enableLoadingState(row, true);
	},
	
	onSettingsLabelClick: function() {
		var dataSource = this.treegrid.dataSource;
		var schemaUId = dataSource.schemaUId;
		var managerName = dataSource.managerName;
		this.treegrid.fireEvent("setquickviewcolumns", schemaUId, managerName);
	},

	onDataSourceBeforeLoadQuickView: function (dataSource, cfg) {
		var row = cfg.attribute.row;
		this.enableLoadingState(row, true);
	},

	onDataSourceQuickViewLoad: function (dataSource, data, config) {
		var row = config.attribute.row;
		this.enableLoadingState(row, false);
		this.transId = false;
		var n = this.render(row, data);
		row.prevNode.style.display = "";
		row.isQuickViewVisible = true;
		this.setActiveState(row, row.isQuickViewVisible);
		var view = row.node.treegrid.view;
		view.updateScroll();
		view.scrollTo(row.prevNode);
	},

	onDataSourceQuickViewLoadException: function (dataSource, responseText, cfg) {
		var row = cfg.attribute.row;
		this.enableLoadingState(row, false);
	},

	enableLoadingState: function (row, isLoading) {
		this.setQuickViewState(row, this.loadingStateCss, isLoading);
	},

	setActiveState: function (row, isActive) {
		this.setQuickViewState(row, this.activeStateCss, isActive);
	},

	setQuickViewState: function (row, style, enabled) {
		var row = Ext.get(row.elNode);
		if (!row) {
			return;
		}
		if (enabled) {
			row.addClass(style);
		} else {
			row.removeClass(style);
		}
	}
});

Terrasoft.treegrid.TreeNodeCheckBox = Ext.extend(Terrasoft.CheckBox, {
	addWrapper: function(container){
		container.addClass(this.baseCls + '-wrap');
		container.dom.tabIndex = this.tabIndex;
		this.wrap = container;
	}
});

Terrasoft.treegrid.TreeNodeRadio = Ext.extend(Terrasoft.Radio, {
	addWrapper: function(container){
		container.addClass(this.baseCls + '-wrap');
		container.dom.tabIndex = this.tabIndex;
		this.wrap = container;
	}
});

if (typeof Sys !== "undefined") { Sys.Application.notifyScriptLoaded(); }