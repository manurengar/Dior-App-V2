sap.ui.define([
	"sap/ui/core/mvc/Controller",
	"sap/ui/model/json/JSONModel",
	"sap/ui/model/Filter",
	"sap/ui/model/FilterOperator",
	'sap/m/MessageStrip',
	"sap/ui/core/Core",
	"sap/m/MessageBox"
], function (Controller, JSONModel, Filter, FilterOperator, MessageStrip, oCore, MessageBox) {
	"use strict";
	var _selectedEmployees = [];
	var _oSelectedEmployees = {};
	var _selectedApEmployees = {};
	var _selectedReEmployees = {};
	var aFilters = [];
	var oFilters = {};
	var bBtnSelected = false;
	var bUpdateError = false;
	var bCode23Triggered = false;
	var oCode22Triggered = {};

	return Controller.extend("DIOR.FR.zfrswbdioovt.controller.Main", {

		onInit: function () {
			this._apElementCounter = 0;
			this._reElementCounter = 0;
			this._ApSelectedAll = false;
			this._ReSelectedAll = false;
		},
		onSelectAllEmp: function (oEvent) {
			const sODataPath = "/OvertimeEventSet";

			if (!bBtnSelected) {
				oEvent.getSource().setText("Désélectionner tous les employés");
				this.byId("EmployeeListCombo").setVisible(false);
				bBtnSelected = true;

				this.byId("OvtEventsTab").bindItems({
					path: sODataPath,
					model: 'employees',
					template: this.byId("TableItemTemplate"),
					templateShareable: true
				});

			} else {
				oEvent.getSource().setText("Sélectionner tous les employés");
				this.byId("EmployeeListCombo").setVisible(true);
				bBtnSelected = false;
				this.byId("OvtEventsTab").unbindItems();
				let aSelKeys = this.byId("EmployeeListCombo").getSelectedKeys();
				this.byId("EmployeeListCombo").removeSelectedKeys(aSelKeys);
			}

		},
		onSectionChange: function (oEvent) {
			var changedItem = oEvent.getParameter("changedItem");
			var isSelected = oEvent.getParameter("selected");

			if (isSelected) {
				_oSelectedEmployees[changedItem.getKey()] = changedItem.getKey();
				oFilters[changedItem.getKey()] = new Filter("EmployeeID", FilterOperator.EQ, "" + changedItem.getKey() + "");
			} else {
				delete _oSelectedEmployees[changedItem.getKey()];
				delete oFilters[changedItem.getKey()];
			}
		},
		onSectionFinish: function (oEvent) {
			const sODataPath = "/OvertimeEventSet";
			console.log(Object.values(oFilters));
			console.log(Object.values(_oSelectedEmployees));
			_selectedEmployees = Object.values(_oSelectedEmployees);
			aFilters = Object.values(oFilters);

			if (Object.values(oFilters).length > 0) {
				this.byId("OvtEventsTab").bindItems({
					path: sODataPath,
					model: 'employees',
					template: this.byId("TableItemTemplate"),
					templateShareable: true,
					filters: aFilters
				});
			} else {
				this.byId("OvtEventsTab").unbindItems();
			}
		},
		onSelectedAp: function (oEvent) {
			const bSelected = oEvent.getParameter("selected");
			const oApCheckBox = oEvent.getSource();
			const oColumnListItem = oApCheckBox.getParent();
			const aCells = oColumnListItem.getCells();
			const oContext = oEvent.getSource().getBindingContext("employees").getObject();

			if (bSelected) {
				this._apElementCounter += 1;
				aCells[7].setEnabled(false);
				_selectedApEmployees[oContext.EntryKey] = oContext;
				this._toggleApBtn();
			} else {
				this._apElementCounter -= 1;
				delete _selectedApEmployees[oContext.EntryKey];
				aCells[7].setEnabled(true);
				this._toggleApBtn();
			}
		},
		onSelectedRe: function (oEvent) {
			const bSelected = oEvent.getParameter("selected");
			const oApCheckBox = oEvent.getSource();
			const oColumnListItem = oApCheckBox.getParent();
			const aCells = oColumnListItem.getCells();
			const oContext = oEvent.getSource().getBindingContext("employees").getObject();

			if (bSelected) {
				this._reElementCounter += 1;
				_selectedReEmployees[oContext.EntryKey] = oContext;
				aCells[6].setEnabled(false);
				this._toggleReBtn();
			} else {
				this._reElementCounter -= 1;
				delete _selectedReEmployees[oContext.EntryKey];
				aCells[6].setEnabled(true);
				this._toggleReBtn();
			}
		},
		_toggleApBtn: function () {
			let oBtn = this.byId("apBtn");
			let totalCounter = this._apElementCounter + this._reElementCounter;
			if (totalCounter > 0 && oBtn.getEnabled() === false) {
				oBtn.setEnabled(true);
			} else if (totalCounter === 0 && oBtn.getEnabled() === true) {
				oBtn.setEnabled(false);
			}
		},
		_toggleReBtn: function () {
			let oBtn = this.byId("apBtn");
			let totalCounter = this._apElementCounter + this._reElementCounter;
			if (totalCounter > 0 && oBtn.getEnabled() === false) {
				oBtn.setEnabled(true);
			} else if (totalCounter === 0 && oBtn.getEnabled() === true) {
				oBtn.setEnabled(false);
			}
		},
		onSelectAllAp: function () {
			const oTable = this.byId("OvtEventsTab");
			const aItems = oTable.getItems();

			// Select all enabled checkboxes
			aItems.forEach((oItem) => {
				const aCells = oItem.getCells();
				// App Items
				const oApCheckBox = aCells[6];
				const bApSelected = oApCheckBox.getSelected();
				const bApEnabled = oApCheckBox.getEnabled();

				// Reject Items
				const oReCheckBox = aCells[7];
				const bReSelected = oReCheckBox.getSelected();
				const bReEnabled = oReCheckBox.getEnabled();

				const oContext = oItem.getBindingContext("employees").getObject();

				if (!this._ApSelectedAll && !this._ReSelectedAll) {
					if (!bApSelected) {
						this._apElementCounter += 1;
						oReCheckBox.setSelected(false);
						oApCheckBox.setEnabled(true);
						_selectedApEmployees[oContext.EntryKey] = oContext;
						if (bReSelected) {
							this._reElementCounter -= 1;
							delete _selectedReEmployees[oContext.EntryKey];
						}
					}
					oApCheckBox.setSelected(true);
					oReCheckBox.setEnabled(false);

				} else if (this._ApSelectedAll && !this._ReSelectedAll) {
					if (bApSelected) {
						this._apElementCounter -= 1;
						delete _selectedApEmployees[oContext.EntryKey];
					}
					oApCheckBox.setSelected(false);
					oReCheckBox.setEnabled(true);

				} else if (!this._ApSelectedAll && this._ReSelectedAll) {
					if (!bApSelected) {
						this._apElementCounter += 1;
						_selectedApEmployees[oContext.EntryKey] = oContext;
					}
					oApCheckBox.setSelected(true);
					oApCheckBox.setEnabled(true);

					if (bReSelected) {
						this._reElementCounter -= 1;
						delete _selectedReEmployees[oContext.EntryKey];
					}
					oReCheckBox.setEnabled(false);
					oReCheckBox.setSelected(false);

				}
			});

			if (!this._ApSelectedAll && !this._ReSelectedAll) {
				this._ApSelectedAll = true;
			} else if (this._ApSelectedAll && !this._ReSelectedAll) {
				this._ApSelectedAll = false;
			} else if (!this._ApSelectedAll && this._ReSelectedAll) {
				this._ApSelectedAll = true;
				this._ReSelectedAll = false;
			}

			this._toggleApBtn();
		},
		onSelectAllRe: function () {
			const oTable = this.byId("OvtEventsTab");
			const aItems = oTable.getItems();

			// Select all enabled checkboxes
			aItems.forEach((oItem) => {
				const aCells = oItem.getCells();
				// App Items
				const oApCheckBox = aCells[6];
				const bApSelected = oApCheckBox.getSelected();
				const bApEnabled = oApCheckBox.getEnabled();

				// Reject Items
				const oReCheckBox = aCells[7];
				const bReSelected = oReCheckBox.getSelected();
				const bReEnabled = oReCheckBox.getEnabled();

				const oContext = oItem.getBindingContext("employees").getObject();

				if (!this._ApSelectedAll && !this._ReSelectedAll) {
					if (!bReSelected) {
						this._reElementCounter += 1;
						oApCheckBox.setSelected(false);
						oReCheckBox.setEnabled(true);
						_selectedReEmployees[oContext.EntryKey] = oContext;
						if (bApSelected) {
							this._apElementCounter -= 1;
							delete _selectedApEmployees[oContext.EntryKey];
						}
					}
					oReCheckBox.setSelected(true);
					oApCheckBox.setEnabled(false);

				} else if (!this._ApSelectedAll && this._ReSelectedAll) {
					if (bReSelected) {
						this._reElementCounter -= 1;
						delete _selectedReEmployees[oContext.EntryKey];
					}
					oReCheckBox.setSelected(false);
					oApCheckBox.setEnabled(true);

				} else if (this._ApSelectedAll && !this._ReSelectedAll) {
					if (!bReSelected) {
						this._reElementCounter += 1;
						_selectedReEmployees[oContext.EntryKey] = oContext;
					}
					oReCheckBox.setSelected(true);
					oReCheckBox.setEnabled(true);

					if (bApSelected) {
						this._apElementCounter -= 1;
						delete _selectedApEmployees[oContext.EntryKey];
					}
					oApCheckBox.setEnabled(false);
					oApCheckBox.setSelected(false);

				}
			});

			if (!this._ApSelectedAll && !this._ReSelectedAll) {
				this._ReSelectedAll = true;
			} else if (!this._ApSelectedAll && this._ReSelectedAll) {
				this._ReSelectedAll = false;
			} else if (this._ApSelectedAll && !this._ReSelectedAll) {
				this._ReSelectedAll = true;
				this._ApSelectedAll = false;
			}
			this._toggleApBtn();
		},

		onAppAll: function () {
			MessageBox.warning("Êtes-vous sûr de soumettre tous les événements marqués?", {
				actions: [MessageBox.Action.YES, MessageBox.Action.NO],
				emphasizedAction: MessageBox.Action.YES,
				onClose: (sSelectedAction) => {
					if (MessageBox.Action.YES === sSelectedAction) {
						console.log(_selectedReEmployees);
						console.log(_selectedApEmployees);
						let sKey = "";
						let oModel = this.getOwnerComponent().getModel("employees");

						// Approval part
						for (const property in _selectedApEmployees) {
							let oContext = _selectedApEmployees[property];
							sKey =
								`/OvertimeEventSet(EmployeeID='${oContext.EmployeeID}',SeqNum='${oContext.SeqNum}',WageType='${oContext.WageType}',EndDay='${oContext.EndDay}',StartDay='${oContext.StartDay}')`;
							oContext.Approval = 1;
							console.log(bCode23Triggered);
							oModel.update(sKey, oContext, {
								success: (oEvent) => {
									bUpdateError = true;
								},
								error: (oEvent) => {
									let oResponse = JSON.parse(oEvent.responseText);
									let sMessage = oResponse.error.message.value;
									let errCode = oResponse.error.code;
									let aErrCode = errCode.match(/(\d+)$/);
									let aEmployeeNumb = sMessage.match(/\d{8}/gm);
									if (aErrCode[0] === '023' && bCode23Triggered === false) {
										bCode23Triggered = true;
										bUpdateError = false;
										MessageBox.error(sMessage);
									} else if (aErrCode[0] === '022') {
										if (oCode22Triggered[aEmployeeNumb[0]] === undefined) {
											oCode22Triggered[aEmployeeNumb[0]] = true;
										    bUpdateError = false;
											MessageBox.error(sMessage);
										}
									}
								}
							});
							delete _selectedApEmployees[property];
						}

						// Rejection part
						for (const property in _selectedReEmployees) {
							let oContext = _selectedReEmployees[property];
							sKey =
								`/OvertimeEventSet(EmployeeID='${oContext.EmployeeID}',SeqNum='${oContext.SeqNum}',WageType='${oContext.WageType}',EndDay='${oContext.EndDay}',StartDay='${oContext.StartDay}')`;
							oContext.Approval = 2;
							console.log(oContext);
							oModel.update(sKey, oContext, {
								success: (oEvent) => {
									bUpdateError = true;
								},
								error: (oEvent) => {
									let oResponse = JSON.parse(oEvent.responseText);
									let sMessage = oResponse.error.message.value;
									let errCode = oResponse.error.code;
									let aErrCode = errCode.match(/(\d+)$/);
									let aEmployeeNumb = sMessage.match(/\d{8}/gm);
									if (aErrCode[0] === '023' && bCode23Triggered === false) {
										bCode23Triggered = true;
										bUpdateError = false;
										MessageBox.error(sMessage);
									} else if (aErrCode[0] === '022') {
										if (oCode22Triggered[aEmployeeNumb[0]] === undefined) {
											oCode22Triggered[aEmployeeNumb[0]] = true;
											bUpdateError = false;
											MessageBox.error(sMessage);
										}
									}
								}
							});
							delete _selectedReEmployees[property];
						}

						//Message confirmation & items deletion from table
						if (this.bUpdateError === true) {
							let oTable = this.byId("OvtEventsTab");
							let aItems = oTable.getItems();

							aItems.forEach((oItem) => {
								let aCells = oItem.getCells();
								if (aCells[6].getSelected() || aCells[7].getSelected()) {
									oTable.removeItem(oItem);
								}
							});
							MessageBox.success("Tous les événements ont été traités");
						}
					}
				}
			});
		}
	});
});