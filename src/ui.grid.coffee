$.widget "talely.grid",

	options :
		headers        : []
		columns        : []
		list           : []
		sortable       : true
		cell_changed   : null
		row_removed    : null
		row_added      : null
		list_reordered : null
		object_clicked : null
		goto_clicked   : null

	_create : ->
		ref = @

		@_table = $ document.createElement('table')
		@_table.addClass "talely-grid"

		@_header = $ document.createElement('thead')
		@_header.addClass "talely-grid-header ui-widget-header"

		@_content = $ document.createElement('tbody')
		@_content.addClass "talely-grid-content"

		@_create_headers()
		@_create_content()

		@_table.append @_header
		@_table.append @_content

		if @options.sortable
			@_content.sortable
				handle : ".icon-reorder"
				update : (event, ui) =>
					ref.options.list = ref._reorder_array()

					ref._trigger "list_reordered", null,
						new_list : ref.options.list
					event.stopPropagation()

		@element.append @_table
		return

	_setOption : ( key, value ) ->
		@_super key, value
		
		switch key
			when "headers" then @_create_headers()
			when "list"    then @_create_content()
			when "columns" then @_create_content()

	_reorder_array : ->
		ref       = @
		new_order = []

		@_content.find("tr").each (i, row) ->
			row = $(row)
			old = row.attr "tg-row-index"

			new_order.push ref.options.list[old]
			row.attr "tg-row-index", i

		new_order

	_create_content : ->
		@_content.empty()
		for row, i in @options.list					
			@_content.append @_create_row row, i

	_create_headers : ->
		@_header.empty()
		titles = []
		titles.push "<tr>"
		for title in @options.headers
			if title is ""
				titles.push "<th class='talely-grid-title'>&nbsp;</th>"
			else
				titles.push "<th class='talely-grid-title'>#{title}</th>"
		titles.push "</tr>"
		@_header.html titles.join ""

	_create_row : ( row_obj, index ) ->
		r = $("<tr></tr>")
				.addClass("talely-grid-row")
				.attr("tg-row-index" , index)

		for column in @options.columns
			r.append @_create_column column, row_obj, index
		
		return r


	_create_column : ( col, row, index ) ->
		c = $("<td></td>")
				.addClass("talely-grid-col")
				.attr("tg-col-name" , col.name)
				.attr("tg-row-index" , index)

		switch col.type
			when "reorder"
				c.append "<i class='icon-reorder'></i>"
			when "input"
				c.append @_add_input_column index, col.name, row[col.name]
			when "checkbox"
				c.append @_add_checkbox_column index, col.name, row[col.name]
				c.css("text-align", "center")
			when "controls"
				c.append @_add_controls_column index, col.name, row[col.name]
			when "select"
				c.append @_add_select_column index, col.name, row[col.name]
			when "goto"
				c.append @_add_goto_column index
			when "object"
				c.append @_add_object_column index, col.name
				c.css("text-align", "center")
			when "delete"
				c.append @_add_delete_column index
			else
				c.append row[col.name]

		return c


	_add_input_column : (index, name, value) ->
		ref   = @
		input = $ document.createElement('input')
		input.attr "type", "text"		
		input.attr "value", value

		input.bind "textchange", (event) ->
			ref.options.list[index][name] = $(@).val()
			ref._trigger "cell_changed", null, 
				value : $(@).val()
				cell  : name
				row   : index

			event.stopPropagation()
		
		return input


	_add_checkbox_column : (index, name, value) ->
		ref   = @
		check = $ document.createElement('input')
		check.attr "type", "checkbox"

		if value then check.prop("checked", true) else check.prop("checked", false)

		check.bind "change", (event) ->
			v = if $(@).is(":checked") then true else false
			ref.options.list[index][name] = v
			ref._trigger "cell_changed", null, 
				value : v
				cell  : name
				row   : index

			event.stopPropagation()
		
		return check


	_add_delete_column : (index) ->
		ref  = @		
		icon = $("<i></i>").addClass("icon-trash")
		icon.bind "click", (event) ->
			if confirm "Delete?"
				ref.options.list.splice index, 1
				$("tr[tg-row-index=#{index}]", ref.element).remove()
				ref._trigger "row_removed", null,
					row   : index

			event.stopPropagation()

		return icon

	_add_select_column : (index, name, list) ->
		ref    = @
		select = $ document.createElement('select')

		for item in list
			select.append "<option value='#{item}' >#{item}</option>"

		select.bind "change", (event) ->

			selected = $(@).val()

			ref.options.list[index][name] = selected
			
			ref._trigger "cell_changed", null, 
				value : selected
				cell  : name
				row   : index

			event.stopPropagation()
		
		return select


	_add_goto_column : (index) ->
		ref  = @		
		icon = $("<i></i>").addClass("icon-search")
		icon.bind "click", (event) ->
			ref._trigger "goto_clicked", null,
				row   : ref.options.list[index]

			event.stopPropagation()

		return icon


	_add_object_column : (index, name) ->
		ref  = @
		icon = $("<i></i>").addClass("icon-expand-alt")
		icon.bind "click", (event) ->
			ref._trigger "object_clicked", null,
				obj   : ref.options.list[index][name]
				index : index
				name  : name

			event.stopPropagation()

		return icon


	_add_controls_column : (index, name, value) ->
		ref = @

		select = $ document.createElement('select')

		for control in EAD.external.dev_tools.controls
			state = if value.type is control.val then "selected='selected'" else ""
			select.append "<option value='#{control.val}' #{state}>#{control.name}</option>"

		select.bind "change", (event) ->

			selected = $(@).val()
			control  = _.find EAD.external.dev_tools.controls, (curr) -> 
				return curr.val is selected

			ref.options.list[index][name] = control.default_value_control
			
			ref._trigger "cell_changed", null, 
				value : control
				cell  : name
				row   : index

			event.stopPropagation()
		
		return select


	add_row : (obj) ->
		i = @options.list.length

		@options.list.push obj		
		@_content.append @_create_row obj, i

		@_trigger "row_added", null, 
			row : i
			obj : obj

	









