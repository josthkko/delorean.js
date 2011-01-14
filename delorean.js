/*
*  Delorean.js -- Raphael-based time series graphing library
*  This work is Copyright by Justin Smestad
*  It is licensed under the Apache License 2.0
*  
*  This code requires jQuery, Raphael.js and Underscore.js
*  http://github.com/jsmestad/delorean.js
*/

(function($, window, document, undefined) {

  var Delorean = function(options) {
    var $chart, data;
    var options = {
      line_colors: ["#4da74d", "#afd8f8", "#edc240", "#cb4b4b", "#9440ed"], // the color theme used for graphs
      date_format: '%m/%d',
      width: 698,
      height: 200,
      label_display_count: 3,
      label_offset: 15,
      margin_left: 5,
      margin_bottom: 5,
      margin_top: 5,
      text_date: {
        "font-size": "10px",
        fill: "#333333"
      },
      text_metric: {
        "font-size": "13px",
        "font-family": "Trebuchet MS, Arial, Helvetica, san-serif"
      },
      stroke_width: 4,
      stroke_width_dense: 2,
      point_size: 5,
      point_size_hover: 7
    };

    function log() {
      if (window.console) {
        console.log(Array.prototype.slice.call(arguments));
      }
    };

    function parseDate(date) {
      d = new Date(date);
      if (isNaN(d)) {
        log("This browser's Date constructor not support ISO8601.");
        d = new Date();
        d.setISO8601(date);
      }
      return d;
    }

    function displayValue(value, precision) {
      if (value >= 0 && value < 1000) {
        return value + '';
      } else if (value >= 1000 && value < 1000000) {
        return (value / 1000).toFixed(precision) + 'K';
      } else if (value >= 1000000) {
        return (value / 1000000).toFixed(precision) + 'M';
      }
    }

    // This draws the X Axis (the dates)
    Raphael.fn.drawXAxis = function(dates, X) {
      var num_to_skip   = Math.round(dates.length / 11);
          y_position    = options.height - 8,
          i             = dates.length;

      var x;
      while (i--) {
        if (i == 0 && dates.length < 20) {
          x = -10;
        } else if (dates.length > 60 && i == 1) {
          x = Math.round(X * i) + 5;
        } else {
          x = Math.round(X * i);
        }

        if ((dates.length < 20) || (i != 0 && i % num_to_skip == 1)) {
          var date = parseDate(dates[i]).strftime(options.date_format);
          this.text(x, y_position, date).attr({"font-size": "10px", fill: "#AFAFAF"}).toBack();
        }
      }
    };

    // This draws the Y Axis (the scale)
    Raphael.fn.drawYAxis = function(max, color) {
      var display  = (options.label_display_count + 1),
          max_more = max * 1.33,
          max_less = max / display,
          offset_x = options.label_offset;

      var y_spacing = Math.round((options.height - options.margin_bottom - options.margin_top) / display);
      var offset_y = (y_spacing * display); // Start from lower number and go up to higher numbers

      for (var scale = 0; scale < max_more; scale += max_less) {
        if (display >= 1 && scale > 0) {
          this.text(offset_x, offset_y, displayValue(Math.round(scale), 0))
            .attr({'font-weight': 'bold','fill': color}).toFront();
        }
        offset_y -= y_spacing;
        display--;
      }
    };

    Raphael.fn.drawChart = function(X, Y) {
      var dates   = _(data).keys(),
          values  = _(data).values();

      var margin_left   = options.margin_left,
          margin_bottom = options.margin_bottom,
          margin_top    = options.margin_top,
          stroke_width  = (dates.length > 45 ? options.stroke_width_dense : options.stroke_width);

      var line_paths = []
      for (var k = 0, kk = values[0].length; k < kk; k++) {
        line_paths[k] = this.path().attr({stroke: options.line_colors[k], "stroke-width": stroke_width, "stroke-linejoin": "round"});
      }
      // Not sure if we need this yet. 
      // var bgp = this.path().attr({stroke: "none", opacity: 0.0, fill: line_color})
                      // .moveTo(margin_left + X * -0.5, options.height - margin_bottom),
      var layer = this.set();
      var point_array = {};

      var tooltip_visible = false,
          leave_timer     = null;

      for (var i = 0, ii = dates.length; i < ii; i++) {
        var x = Math.round(X * i);

        point_array[x] = [];

        var stroke_color      = "#FFFFFF",
            point_size        = options.point_size,
            point_size_hover  = options.point_size_hover,
            first_point       = (i == 0 ? true : false);

        if (dates.length > 45 && dates.length <= 90) {
          point_size = 3;
          point_size_hover = 5;
        } else if (dates.length > 90) {
          point_size = 0;
          point_size_hover = 3;
        }

        for (var j = 0, jj = values[i].length; j < jj; j++) {
          var value = values[i][j];
          var y = Math.round(options.height - margin_bottom - Y * value);

          if (value < 0) {
            y = Math.round(options.height - margin_bottom - Y * 0);
          }

          if (dates.length < 45) {
            // bgp[(first_point ? "lineTo" : "cplineTo")](x, y, 10);
            line_paths[j][(first_point ? "moveTo" : "cplineTo")](x, y, 10);
          } else {
            // bgp[(first_point ? "lineTo" : "lineTo")](x, y, 10);
            line_paths[j][(first_point ? "moveTo" : "lineTo")](x, y, 10);
          }

          point = this.circle(x, y, point_size).attr({fill: options.line_colors[j], stroke: stroke_color});
          point.insertAfter(line_paths[j]);

          point_array[x].push(point);
        }

        layer.push(this.rect(X * i, 0, X, options.height - margin_bottom)
             .attr({stroke: "none", fill: "#FFFFFF", opacity: 0}));

        (function(rect, points, x) {
          rect.hover(function() {
            _.each(points[x], function(point) {
              point.attr({"r": point_size_hover});
            });
          }, function() {
            _.each(points[x], function(point) {
              point.attr({"r": point_size});
            });
          });
        })(layer[layer.length - 1], point_array, x);

      }
    };

    return {
      init: function(target_, data_, options_) {
        $.extend(true, options, options_);

        $chart = $(target_);
        $chart.children().remove();

        data = data_;
        var array_length = data.length;
        while (array_length--) {
          data[array_length] = parseDate(data[array_length]);
        }
      },

      render: function() {
        var r       = Raphael($chart.get(0), options.width, options.height),
            dates   = _(data).keys(),
            values  = _(data).values();

        if(_.isArray(values[0])) {
          var max = _(_(values).flatten()).max();
        } else {
          var max = _(values).max();
          _.each(data, function(value, key) {
            data[key] = [value];
          });
          log(data);
        }

        var X = (options.width / dates.length),
            Y = (options.height - options.margin_bottom - options.margin_top) / max;

        r.drawXAxis(dates, X);
        r.drawChart(X, Y);
        r.drawYAxis(max, "#AFAFAF");
      }
    };
  };

  $.delorean = function(target, data, options) {
    var delorean = new Delorean();
    delorean.init(target, data, options);
    return delorean;
  };

})(jQuery, window, this);
