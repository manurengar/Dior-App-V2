sap.ui.define([
	"sap/ui/core/Control"
], (Control) => {
	"use strict";

	return Control.extend("DIOR.FR.zfrswbdioovt.control.ProductRating", {
		metadata : {
			aggregations : {
				_icon : {type : "sap.ui.core.Icon", multiple: false, visibility : "hidden"},
				_text : {type : "sap.m.Text", multiple: false, visibility : "hidden"}
			},
		},

		init() {},

		renderer(oRM, oControl) {}
	});
});