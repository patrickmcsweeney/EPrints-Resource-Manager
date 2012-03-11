document.observe( 'dom:loaded', function() {
	document.observe('click', updateResourceSelection);
	window.addRemovalButtons();
});

window.addRemovalButtons = function() {
	$$('.ep_resourcemanager_tag_active').each(function(tag) {

		var image_uri = rel_path + '/style/images/xit.gif';

		var remtag = new Element('button');
		remtag.setStyle({
			'background': 'url('+image_uri+') 0 0',
			'cursor': 'pointer',
			'height': '10px',
			'width': '10px',
			'outline-style': 'none',
			'outline-color': 'invert',
			'outline-width': '0px',
			'border': '0px',
			'padding': '0px',
			'margin': '0px 10px 0px 1px',
			'font-size': '100%'
		});
	
		remtag.style.verticalAlign = 'middle';

		remtag.observe('click', function() {
			window.location = tag.readAttribute('href');
		});
		remtag.observe('mouseover', activateClearButton);
		remtag.observe('mouseout', deactivateClearButton);

		tag.observe('mouseover', activateClearButton);
		tag.observe('mouseout', deactivateClearButton);
		tag.insert({ after: remtag });

		function activateClearButton() {
			remtag.setStyle({ 'background': 'url('+image_uri+') -10px 0' });
		}

		function deactivateClearButton() {
			remtag.setStyle({ 'background': 'url('+image_uri+') 0 0' });
		}
	});
}

window.selectAll = function(event) {
	var element = event.element();
	var type = arguments[1];
	var resourceList = $$('#'+type+'_manageable_list .ep_manageable');
	if (element.readAttribute('checked')) {
		element.writeAttribute('checked', false);
		resourceList.each(function(resource) {
			if (resource.hasClassName('ep_manageable_selected')) {
				resource.removeClassName('ep_manageable_selected');
			}
		});
	} else {
		element.writeAttribute('checked', true);
		resourceList.each(function(resource) {
			if (!resource.hasClassName('ep_manageable_selected') && resource.visible()) {
				resource.addClassName('ep_manageable_selected');
			}
		});
	}
}

window.updateResourceSelection = function(event) {
	/* 
	 * The left click detection is not required under IE.
	 * But this test needs to be done to preserve right clicks
	 * in other browsers.
	 */
	if (!Prototype.Browser.IE && !event.isLeftClick()) return;
	var element = event.element();
	if (ignoreElement(element)) {
		return;
	} else if (!Object.isUndefined(element = event.findElement('.ep_manageable'))) {
		checkbox = $$('#'+element.readAttribute('id')+' .ep_resource_manager_select_check')[0];
		if (inBulkSelection(element)) {
			element.removeClassName('ep_manageable_selected');
			if (Object.isUndefined(event.findElement('.ep_resource_manager_select_check'))) {
				checkbox.writeAttribute('checked', false);
			}
		} else {
			element.addClassName('ep_manageable_selected');
			if (Object.isUndefined(event.findElement('.ep_resource_manager_select_check'))) {
				checkbox.writeAttribute('checked', true);
			}
		}
		checkbox.blur();
	}
}

window.inBulkSelection = function(element) {
	var checkbox = $$('#'+element.readAttribute('id')+' .ep_resource_manager_select_check')[0];
	return checkbox.readAttribute('checked') || element.hasClassName('ep_manageable_selected');
}

window.enableSearch = function(event) {
	var element = event.element();
	var type = arguments[1];
	event.stop();
	element.observe('keyup', function(event) {
		filterItemList(type, element.getValue());
	});
	element.observe('blur', function(event) {
		element.stopObserving('keyup');
		element.stopObserving('blur');
	});
}

window.filterItemList = function(type, filterString) {
	var resourceList = $$('#'+type+'_manageable_list .ep_manageable');
	if (filterString.length) {
		resourceList.each(function(resourceItem) {
			var link = resourceItem.down('span.ep_manageable_data_title');
			if (!Object.isUndefined(link)) {
				var regex = new RegExp('^'+RegExp.escape(filterString.replace(/\s/, '')), 'i');
				var linktext = link.innerHTML.replace(/\s/, '');
				if (regex.match(linktext)) {
					if (!resourceItem.visible()) {
						resourceItem.show();
					}
				} else {
					resourceItem.hide();
				}
			}
		});
	} else {
		resourceList.each(function(resourceItem) {
			if (!resourceItem.visible()) {
				resourceItem.show();
			}
		});
	}
}

window.resetFilter = function(filter) {
	var type = filter.match(/dynamic_(\w+?)_search/)[1];
	var filter = $(filter);
	if (!Object.isUndefined(filter)) {
		filter.clear();
		filterItemList(type, '');
	}
}

window.executeBulkAction = function(event) {
	var type = arguments[1];
	var form = event.findElement('.ep_bulkaction_form');
	form.submit();
	/*var eprintids = $('bulk_eprintids_'+type);
	if (!Object.isUndefined(eprintids)) {
		var raweprintids = new Array();
		$$('#'+type+'_manageable_list .ep_manageable_selected').each(function(element) {
			var elementid = element.readAttribute('id');
			elementid = elementid.match(/manageable_id_(\d+)/)[1];
			raweprintids.push(elementid);
		});
		$('bulk_eprintids_'+type).setValue(raweprintids.join());
		form.submit();
	}*/
}

window.ignoreElement = function(element) {
	if (element.hasClassName('ep_manageable_action_button')) {
		return true;
	}
	if (element.hasClassName('ep_form_action_button')) {
		return true;
	}
	if (element.hasClassName('ep_manageable_data_title')) {
		return true;
	}
	if (element.tagName.toLowerCase() == 'a') {
		return true;
	}

	return false;
}

function refreshShare(eprintid,citation)
{
	new Ajax.Request( rel_path+'/cgi/users/ajax/render_share', 
		{ 
			parameters:'eprintid='+eprintid+"&citation="+citation,
			method:'GET',
			onSuccess:function(trans){ $('manageable_id_'+eprintid).innerHTML = trans.responseText; } 
		} );

	return false;
}
