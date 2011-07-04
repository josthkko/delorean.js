# **Delorean.js** is an opintionated time-series graphing library which
# focuses on balancing minimal amounts of readable code with aesthetics.
# These two things combine to achieve, what I believe to be, the first
# graphing library that is small, performant, and beautiful.
#
# Developers no longer have to worry about how to make various size datasets
# look ideal inside of their web applications. Delorean.js figures out the
# optimal display criteria for the provided dataset, if its too large, it
# will distill the data into a trended graph.
#
# Trying to keep with the minimalist idea, Delorean.js depends on only two
# external libraries: [Underscore.js](http://underscorejs.documentcloud.com)
# and [jQuery](http://jquery.com).
#
# The [source for Delorean.js](http://github.com/jsmestad/delorean.js) is
# available on GitHub, and released under the Apache license.
#

### Features
#
#### Data Distillation _(also known as Trending)_
# Delorean.js allows users to pass a large dataset, 60 days worth of
# hourly data for example, and graph it into a constrainted area of
# your web application. When enabling distillation, Delorean.js
# will take the 17,280 data points, calculate that it can only graph
# 42 points in a 700px wide graph, group them into groups of ~412
# data points, calculate the average, and render the chart.
#
# This allows web developers to use Javascript localStorage and only
# fetch a given dataset once. When you resize the graph, just ask
# delorean to recalculate the distillation.
#
#### Outliers _(work in progress)_
# Delorean.js has an outliers mode. This is similar to data distillation,
# but it is used to isolate outliers (in our case we call an outlier,
# anything that is two standard deviations from the mean). The reason
# we do this is to eliminate the use-case where a single bad data point
# will blow out the scale of the y-axis making the graph useless.
#
#### No Tick Interval
# Leave behind the dreaded tick interval configuration. Delorean.js uses
# the first two data points to calculate the interval of your graph. This
# greatly simplifies and improves the perfomrance of the codebase, but
# means that you better cleanse your dataset before passing it to the
# client. Sorry, but we don't believe in giving developers saftey scissors.


#### Usage
#
# The JSON object for a single delorean.js line graph looks like:
#
#     var stats = {
#       "2011-10-08T09:30:00Z": 890234,
#       "2010-12-31T09:30:00Z": 590234,
#       "2010-12-30T09:30:00Z":   3024,
#       "2010-12-29T09:30:00Z":  29134,
#       "2010-12-28T09:30:00Z":  82372
#     }
#
# For a multi-line graph, just make the values into an array:
#
#     var stats = {
#       "2011-10-08T09:30:00Z": [890234, 283749],
#       "2010-12-31T09:30:00Z": [590234, 827],
#       "2010-12-30T09:30:00Z": [3024, 0],
#       "2010-12-29T09:30:00Z": [29134, 9827],
#       "2010-12-28T09:30:00Z": [82372, 132]
#     }
#
# Then initialize a new Delorean.js chart:
#
#     var chart = $.delorean('#week_chart', stats, {});
#     chart.render();
#
Delorean = (options) ->

  ## Configuration Options

  # * **line_colors** -- a set of colors in hex format that are used sequentially.
  #   If more lines are requested than exist in the array, Delorean.js will
  #   automatically ligthen and darken the original colors (see tintColor helper
  #   to see how this works).
  #   *Default:* `["#4da74d", "#afd8f8", "#edc240", "#cb4b4b", "#9440ed"]`
  #
  # * **line_labels** -- accepts an array of Strings that allow you to configure
  #   labels for each of the lines passed into the array.
  #   *Example:* `["Total", "Reads", "Writes", "Inserts"]`  
  #   *Default:* `[]`
  #
  # * **date_format** -- configures the display of the dates across the x-axis.
  #   See strftime.js for example usage.  
  #   *Default:* `'%m/%d` meaning Jan 01 is 01/01
  #
  # * **height** and **width** -- accepts an integer value to determine the size
  #   of the resulting graph
  #
  # * **label\_display\_count** -- accepts an integer value that sets the number of
  #   y-axis labels to calculate and display.
  #
  # * **label_offset** -- is a number of pixels to offset the x-axis labels, this
  #   is similar to padding-left for the graph. This should not require any tweaking,
  #   unless you change the label css.
  #
  # * **margin_left** -- sets the left margin for the graph
  #
  # * **margin_bottom** -- sets the bottom margin for the graph
  #
  # * **margin_top** -- sets the top margin for the graph
  #
  # * **text_date**
  #
  # * **text_metric**
  #
  # * **trend** -- enable or disable data trending. When enabled, delorean will
  #   calculate the maximum amount of points that it can graph while maintaining
  #   visual appeal and then group and average the points together. See distillData
  #   for the code.  
  #   *Default:* `false`
  #
  # * **grid_color** -- set the hex color for the x and y axis grid lines.  
  #   *Default:* `#f5f5f5` which is a very light gray
  #
  # * **display_x_grid** and *display_y_grid* -- are boolean flags that enable or
  #   disable drawing axis grid lines.  
  #   *Default:* `true`
  #
  # * **stroke_width**
  #
  # * **stroke\_width\_dense**
  #
  # * **point_size** -- the pixel size of each point in it's default state. Note, that
  #   this functionality currently is overriden when trending is turned on, or you have
  #   more than 45 data points. This will be fixed in an upcoming release.  
  #   *Default:* `5`
  #
  # * **point\_size\_hover** -- the pixel size of points when they are hovered over. See
  #   note in the point_size definition, this variable is bound to this same constraint.  
  #   *Default:* `7`
  #
  # * **enable_tooltips** -- is a boolean flag to enable or disable tooltips. See
  #   tooltip documentation below for more information.  
  #   *Default:* `false`
  #
  # * **verify_libraries** -- is a boolean flag to enable crude dependency checking
  #   at runtime.  
  #   *Default:* `true`
  #
  options =
    line_colors: [ "#4da74d", "#afd8f8", "#edc240", "#cb4b4b", "#9440ed" ]

    line_labels: []

    date_format: "%m/%d"

    height: 200
    width: 700

    label_display_count: 3
    label_offset: 15

    margin_left: 5
    margin_bottom: 5
    margin_top: 5

    text_date:
      fill: "#999"
      "font-size": "10px"

    text_metric:
      "font-size": "13px"
      "font-family": "Arial, san-serif"

    trend: false
    grid_color: "#f5f5f5"
    display_x_grid: true
    display_y_grid: true
    stroke_width: 4
    stroke_width_dense: 2
    point_size: 5
    point_size_hover: 7
    enable_tooltips: false
    verify_libraries: true

  ### Helper Functions

  # The functions below are all private, meaning they cannot be
  # invoked directly. They are below for documentation purposes
  # only.

  #### Log
  # Wraps the log function allowing *log* statements to be left
  # in production code without causing errors.
  log = ->
    window.console and console.log(Array::slice.call(arguments))

  #### Mean
  # Calculates the mean of an Array of numbers
  mean = (numbers) ->
    total = 0

    i = 0
    while i < numbers.length
      total += numbers[i]
      i += 1
    total / numbers.length

  #### Median
  # Calculates the median of an Array of numbers
  median = (numbers) ->
    median = 0
    numsLen = numbers.length
    numbers.sort()
    if numsLen % 2 == 0
      median = (numbers[numsLen / 2 - 1] + numbers[numsLen / 2]) / 2
    else
      median = numbers[(numsLen - 1) / 2]
    median

  #### Mode
  # Calculates the mode of an Array of numbers
  mode = (numbers) ->
    modes = []
    count = []
    maxIndex = 0
    i = 0
    while i < numbers.length
      number = numbers[i]
      count[number] = (count[number] or 0) + 1
      maxIndex = count[number]  if count[number] > maxIndex
      i += 1
    for i of count
      modes.push Number(i)  if count[i] == maxIndex  if count.hasOwnProperty(i)
    modes

  #### Range
  # Calculates the range of an Array of numbers
  range = (numbers) ->
    numbers.sort()
    [ numbers[0], numbers[numbers.length - 1] ]

  #### parseDate
  # Helper function that ensures every browser supports the Date ISO8601 standard.
  # The obvious one that does not is Safari.
  parseDate = (date) ->
    d = (if _.isDate(date) then date else new Date(date))
    if isNaN(d)
      log "ISO 8601 Date constructor not supported in this browser."
      d = new Date()
      d.setISO8601 date
    d

  #### calculateLabelWidth
  calculateLabelWidth = (date) ->
    d = parseDate(date).strftime(options.date_format)
    texty = r.text(0, 0, d).attr(options.text_date)
    label_width = Math.round(texty.getBBox().width + 22.5)
    texty.remove()
    label_width

  #### displayValue
  displayValue = (value, precision) ->
    if value >= 0 and value < 1000
      value.toString()
    else if value >= 1000 and value < 1000000
      (value / 1000).toFixed(precision) + "K"
    else
      (value / 1000000).toFixed(precision) + "M"

  #### tooltip
  tooltip = (event, values) ->
    unless $("#tooltip").length
      $("body").append "<div id=\"tooltip\"><div id=\"tooltip_inner\">" + values.join("<br />") + "</div></div>"
    else
      $("#tooltip_inner").html values.join("<br />")
    svg = $(event.target.parentNode)
    svg_x = svg.offset().left + svg.outerWidth()
    svg_y = svg.offset().top + svg.outerHeight()
    tooltip = $("#tooltip").show()
    tooltip_inner = $("#tooltip_inner")
    event_x = event.pageX
    event_y = event.pageY
    tooltip_x = tooltip.outerWidth()
    tooltip_y = tooltip.outerHeight()
    tooltip.css
      top: (if (event_y + tooltip_y > svg_y) then event_y - (tooltip_y / 2) else event_y)
      left: (if (event_x + tooltip_x + 20 > svg_x) then event_x - tooltip_x - 15 else event_x + 20)

  #### tintColor
  tintColor = (color, value) ->
    color = color.substring(1,color.length) if color.length > 6
    rgb = parseInt(color, 16)
    red = Math.abs(((rgb >> 16) & 0xFF) + v)
    green = Math.abs(((rgb >> 8) & 0xFF) + v)
    blue = Math.abs((rgb & 0xFF) + v)

    red = if red > 255 then red - (red - 255) else red
    green = if green > 255 then green - (green - 255) else green
    blue = if blue > 255 then blue - (blue - 255) else blue

    red = if Number(red < 0 or isNaN(red)) then 0 else ((red > 255) ? 255 : red)
    green = if Number(green < 0 or isNaN(green)) then 0 else ((green > 255) ? 255 : green)
    blue = if Number(blue < 0 or isNaN(blue)) then 0 else ((blue > 255) ? 255 : blue)
    "#" + red.toPaddedString(2) + green.toPaddedString(2) + blue.toPaddedString(2)

  #### selectColor
  selectColor = (index) ->
    c = options.line_colors[index]
    if _.isUndefined(c)
      v = (index % options.line_colors.length)
      c = options.line_colors[v]
      c = tintColor(c, Math.round(index / options.line_colors.length)+50)
    c

  #### distillData
  distillData = (data, force) ->
    if _.isNull(distilled_data) or force == true
      distilled_data = {}
      tmp_data = _.clone(data)
      dates = _(tmp_data).keys()
      max_points = Math.round(options.width / 17)
      every_x = (if (dates.length >= max_points) then Math.round(dates.length / max_points) else 1)
      date_groups = []
      normalized_data = {}
      point_num = (if (every_x == 1) then dates.length else max_points - 1)

      _(point_num).times (i) ->
        date_groups[i] = dates.splice(0, every_x)

      _.each date_groups, (date_group) ->
        values = _.map(date_group, (d) ->
          tmp_data[d]
        )
        if _.isArray(values[0])
          avg = []
          _(values[0].length).times (i) ->
            set = _.map(values, (v) ->
              v[i]
            )
            avg.push Math.round(_(set).reduce((sum, n) ->
              sum + n
            , 0) / set.length)
        else
          avg = Math.round(_(values).reduce((sum, n) ->
            sum + n
          , 0) / values.length)
        display_date = _.map(date_group, (d) ->
          parseDate d
        )
        starting_date = _(display_date).chain().sort((a, b) ->
          return 1 if a > b
          return -1 if a < b
          0
        ).head().value()
        distilled_data[starting_date.toISOString()] = avg
    distilled_data

  #### drawXAxis
  Raphael.fn.drawXAxis = (dates, X) ->
    dates_length = dates.length
    num_to_skip = Math.round(dates_length / 11)
    y_position = options.height - 8
    label_width = calculateLabelWidth(dates[0])
    total_possible = Math.round(options.width / label_width)
    every_x = Math.round(dates_length / total_possible)
    if every_x == 0
      date_labels = dates
    else
      date_labels = _.select(dates, (d, index) ->
        index % every_x == 0
      )
    i = date_labels.length
    while i--
      x = Math.round(X * _.indexOf(dates, date_labels[i], true)) + (options.label_offset + 15)
      date = parseDate(date_labels[i]).strftime(options.date_format)
      @text(x, y_position, date).attr(options.text_date).toBack()
      @path([ "M", x, y_position, "V", 0 ]).attr(stroke: options.grid_color).toBack()  if options.display_x_grid

  #### drawYAxis
  Raphael.fn.drawYAxis = (max) ->
    display = options.label_display_count + 1
    max_more = max * 1.33
    max_less = max / display
    offset_x = options.label_offset
    y_spacing = Math.round((options.height - options.margin_bottom - options.margin_top) / display)
    offset_y = y_spacing * display
    scale = 0

    while scale < max_more
      if display >= 1 and scale > 0
        if options.display_y_grid
          j = 0
          while j <= 1
            t = (if j == 1 then offset_y + (y_spacing / 2) else offset_y)
            @path([ "M", offset_x, t, "H", options.width - 5 ]).attr(stroke: options.grid_color).toBack()
            @path([ "M", offset_x, offset_y - (y_spacing / 2), "H", options.width - 5 ]).attr(stroke: options.grid_color).toBack()  if display == 1 and j == 1
            j++
        @text(offset_x, offset_y, displayValue(Math.round(scale), 0)).attr(
          fill: options.text_date["fill"]
          "font-weight": "bold"
        ).toFront()
      offset_y -= y_spacing
      display--
      scale += max_less

  #### drawChart
  Raphael.fn.drawChart = (X, Y) ->
    line_paths = []
    dates = _(data).keys()
    values = _(data).values()
    margin_left = options.margin_left
    margin_bottom = options.margin_bottom
    margin_top = options.margin_top
    stroke_width = (if dates.length > 45 then options.stroke_width_dense else options.stroke_width)
    k = 0
    kk = values[0].length

    while k < kk
      line_paths[k] = @path().attr(
        stroke: selectColor(k)
        "stroke-width": stroke_width
        "stroke-linejoin": "round"
      )
      k++
    layer = @set()
    point_array = []
    values_array = []
    tooltip_visible = false
    leave_timer = null
    dates_length = dates.length
    i = 0

    while i < dates_length
      x = Math.round(X * i) + (options.label_offset + 15)
      point_array[x] = []
      values_array[x] = []
      stroke_color = "#fff"
      point_size = options.point_size
      point_size_hover = options.point_size_hover
      first_point = i == 0
      if dates_length > 45 and dates_length <= 90
        point_size = 3
        point_size_hover = 5
      else if dates_length > 90
        point_size = 0
        point_size_hover = 3
      j = 0

      while j < values[i].length
        value = values[i][j]
        y = Math.round(options.height - margin_bottom - Y * value)
        y = Math.round(options.height - margin_bottom - Y * 0)  if value < 0
        if dates_length <= 45
          line_paths[j][(if first_point then "moveTo" else "cplineTo")] x, y, 10
        else if dates_length <= 90
          line_paths[j][(if first_point then "moveTo" else "cplineTo")] x, y, 4
        else
          line_paths[j][(if first_point then "moveTo" else "cplineTo")] x, y, 1
        point = @circle(x, y, point_size).attr(
          fill: options.line_colors[j]
          stroke: stroke_color
        )
        point.insertAfter line_paths[j]
        point_array[x].push point
        values_array[x].push value
        j++
      layer.push @rect(x, 0, X, options.height - margin_bottom).attr(
        stroke: "none"
        fill: "#fff"
        opacity: 0
      )
      ((rect, points, x, values) ->
        rect.hover(->
          _.each points[x], (point) ->
            point.attr r: point_size_hover
        , ->
          _.each points[x], (point) ->
            point.attr r: point_size

          $("#tooltip").hide()
        ).mousemove (event) ->
          tooltip event, values[x]  if options.enable_tooltips
      ) layer[layer.length - 1], point_array, x, values_array
      i++

  ## Instance Methods
  #
  # These are methods that you can invoke on any Delorean.js instance

  #### init
  # This method is implicitly invoked. You shouldn't ever need to call
  # this directly. See *$.delorean()* for details on how this is used.
  init: (target_, data_, options_) ->
    $.extend true, options, options_
    raw_data = _.clone(data_)
    data = (if options.trend == true then distillData(raw_data, true) else raw_data)
    if options.verify_libraries
      throw "You must include the strftime.js file before executing Delorean.js" if _.isUndefined(Date::strftime) or _.isUndefined(Date::setISO8601)
      throw "You must include the raphael.js file before executing Delorean.js" if _.isUndefined(Raphael)
      throw "You must include the raphael.path.methods.js file before executing Delorean.js" if _.isUndefined(Raphael.el.lineTo)
    chart = $(target_)
    chart.children().remove()
    r = Raphael(chart.get(0), options.width, options.height)

  #### distill
  # Calling this will cause the dataset utilized by the chart to be distilled
  # down to a trended dataset. This allows you to pass more data points than
  # displayable pixels.
  #
  # This method takes one argument, force, which is a boolean value telling
  # the *distillData* function to force a data refresh or not.
  distill: (force) ->
    distillData force

  #### render
  # This will draw the actual chart. If not invoked, the chart will never be
  # inserted into the DOM.
  #
  # Currently calling render multiple times will cause the graph to re-render,
  # but this has not been extensively tested.
  render: ->
    dates = _(data).keys()
    values = _(data).values()
    if _.isArray(values[0])
      max = _(_(values).flatten()).max()
    else
      max = _(values).max()
      _.each data, (value, key) ->
        data[key] = [value]
    X = (options.width - (options.label_offset + 15)) / dates.length
    Y = (options.height - options.margin_bottom - options.margin_top) / max
    r.drawXAxis dates, X
    r.drawChart X, Y
    r.drawYAxis max

## Initializer

### $.delorean
# This will initialize a new Delorean.js chart.
#
#     var chart = $.delorean(#chart_id, {...data...}, {...options...});

$.delorean = (target, data, options) ->
  delorean = new Delorean()
  delorean.init target, data, options
  delorean

