Ext.namespace('Ext.ux');

Ext.ux.GUID = function(config) {
	if (!config) {
		try {
			this.id = (new ActiveXObject('Scriptlet.TypeLib').GUID).substr(1, 36);
		} catch(e) {
			this.id = this.createGUID();
		}
	} else {
		Ext.Ajax.request(config);
	}
};

Ext.ux.GUID.prototype.valueOf = function(){ return this.id; };
Ext.ux.GUID.prototype.toString = function(){ return this.id; };

Ext.ux.GUID.prototype.createGUID = function() {

	var dg = new Date(1582, 10, 15, 0, 0, 0, 0).getTime();
	var dc = new Date().getTime();
	var t = (dg < 0) ? Math.abs(dg) + dc : dc - dg;
	var h = '-';
	var tl = Ext.ux.GUID.getIntegerBits(t, 0, 31);
	var tm = Ext.ux.GUID.getIntegerBits(t, 32, 47);
	var thv = Ext.ux.GUID.getIntegerBits(t, 48, 59) + '1'; // version 1, security version is 2
	var csar = Ext.ux.GUID.getIntegerBits(Math.randRange(0, 4095), 0, 7);
	var csl = Ext.ux.GUID.getIntegerBits(Math.randRange(0, 4095), 0, 7);

	var n = Ext.ux.GUID.getIntegerBits(Math.randRange(0, 8191), 0, 7) +
		Ext.ux.GUID.getIntegerBits(Math.randRange(0, 8191), 8, 15) +
			Ext.ux.GUID.getIntegerBits(Math.randRange(0, 8191), 0, 7) +
				Ext.ux.GUID.getIntegerBits(Math.randRange(0, 8191), 8, 15) +
					Ext.ux.GUID.getIntegerBits(Math.randRange(0, 8191), 0, 15); // this last number is two octets long
	return tl + h + tm + h + thv + h + csar + csl + h + n;
};

Ext.ux.GUID.isGUID = function(val) {
	var reg = new RegExp('^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$');
	return reg.test(val);
};

Ext.ux.GUID.isEmptyGUID = function(val) {
	var reg = new RegExp('(0){8}-(0){4}-(0){4}-(0){4}-(0){12}');
	return reg.test(val);
};

Ext.ux.GUID.getIntegerBits = function(val, start, end) {
	var base16 = Ext.ux.GUID.returnBase(val, 16);
	var quadArray = base16.split('');
	var quadString = '';
	var i = 0;
	for (i = Math.floor(start / 4); i <= Math.floor(end / 4); i++) {
		if (!quadArray[i] || quadArray[i] == '') {
			quadString += '0';
		} else {
			quadString += quadArray[i];
		}
	}
	return quadString;
};

Ext.ux.GUID.returnBase = function(number, base) {
	return number.toString(base).toUpperCase();
};

Ext.applyIf(Math, {
	/**
	 * extend Math class with a randRange method
	 * @return {Number} A random number greater than or equal to min and less than or equal to max.
	*/
	randRange: function(min, max) {
		return Math.max(Math.min(Math.round(Math.random() * max), max), min);
	}
});