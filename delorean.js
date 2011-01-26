/*
* Delorean.js -- Raphael-based time series graphing library
* This work is Copyright by Justin Smestad
* It is licensed under the Apache License 2.0
*
* This code requires jQuery, Underscore.js, and Raphael.js
* http://github.com/jsmestad/delorean.js
*/

(function($, window, document, undefined) {
  // Constructor.
  var Delorean = function(options) {
    // Empty vars.
    var chart, data, r;

    // Defaults.
    options = {
      // Colors for graphs.
      line_colors: [
        '#4da74d',
        '#afd8f8',
        '#edc240',
        '#cb4b4b',
        '#9440ed'
      ],
      date_format: '%m/%d',
      width: 700,
      height: 200,
      label_display_count: 3,
      label_offset: 15,
      margin_left: 5,
      margin_bottom: 5,
      margin_top: 5,
      text_date: {
        'fill': '#999',
        'font-size': '10px'
      },
      text_metric: {
        'font-size': '13px',
        'font-family': 'Arial, san-serif'
      },
      grid_color: '#f5f5f5',
      display_x_grid: true,
      display_y_grid: true,
      stroke_width: 4,
      stroke_width_dense: 2,
      point_size: 5,
      point_size_hover: 7,
      enable_tooltips: false
    };

    function log() {
      window.console && console.log(Array.prototype.slice.call(arguments));
    }

    function parseDate(date) {
      d = new Date(date);

      if (isNaN(d)) {
        log('ISO 8601 Date constructor not supported.');
        d = new Date();
        d.setISO8601(date);
      }

      return d;
    }

    function calculateLabelWidth(date) {
      d = parseDate(date).strftime(options.date_format);
      var texty = r.text(0, 0, d).attr(options.text_date);
      // TODO: 22.5 should be configurable (this is currently purely for styling)
      var label_width = Math.round(texty.getBBox().width + 22.5);
      texty.remove();
      return label_width;
    }

    function displayValue(value, precision) {
      if (value >= 0 && value < 1000) {
        return value.toString();
      } else if (value >= 1000 && value < 1000000) {
        return (value / 1000).toFixed(precision) + 'K';
      } else if (value >= 1000000) {
        return (value / 1000000).toFixed(precision) + 'M';
      }
    }

    function tooltip(event, values) {
      if (!$('#tooltip').length) {
        $('body').append('<div id="tooltip"><div id="tooltip_inner">' + values.join('<br />') + '</div></div>');
      } else {
        $('#tooltip_inner').html(values.join('<br />'));
      }

      var svg = $(event.target.parentNode);
      var svg_x = svg.offset().left + svg.outerWidth();
      var svg_y = svg.offset().top + svg.outerHeight();

      // Alias tool tip.
      var tooltip = $('#tooltip').show();
      var tooltip_inner = $('#tooltip_inner');

      // Event coordinates.
      var event_x = event.pageX;
      var event_y = event.pageY;

      // Tool tip coordinates.
      var tooltip_x = tooltip.outerWidth();
      var tooltip_y = tooltip.outerHeight();

      // Move tool tip.
      tooltip.css({
        'top': (event_y + tooltip_y > svg_y) ? event_y - (tooltip_y / 2) : event_y,
        'left': (event_x + tooltip_x + 20 > svg_x) ? event_x - tooltip_x - 15 : event_x + 20
      });
    };

    // This draws the X Axis (the dates).
    Raphael.fn.drawXAxis = function(dates, X) {
      var x, date, date_labels, i;
      var dates_length = dates.length;
      var num_to_skip = Math.round(dates_length / 11);
      var y_position = options.height - 8;
      var label_width = calculateLabelWidth(dates[0]);
      var total_possible = Math.round(options.width / label_width);
      var every_x = Math.round(dates_length / total_possible);

      if (every_x === 0) { 
        date_labels = dates;
      } else {
        date_labels = _.select(dates, function(d, index) { return (index % every_x === 0) });
      }

      i = date_labels.length;

      while (i--) {
        x = Math.round(X * _.indexOf(dates, date_labels[i], true)) + (options.label_offset + 15);
        date = parseDate(date_labels[i]).strftime(options.date_format);
        this.text(x, y_position, date).attr(options.text_date).toBack();

        if (options.display_x_grid) {
          this.path(["M", x, y_position, "V", 0]).attr({'stroke': options.grid_color}).toBack();
        }

      }
    };

    // This draws the Y Axis (the scale).
    Raphael.fn.drawYAxis = function(max) {
      var display = options.label_display_count + 1;
      var max_more = max * 1.33;
      var max_less = max / display;
      var offset_x = options.label_offset;
      var y_spacing = Math.round((options.height - options.margin_bottom - options.margin_top) / display);

      // Start from lower number and go higher.
      var offset_y = y_spacing * display;

      for (var scale = 0; scale < max_more; scale += max_less) {
        if (display >= 1 && scale > 0) {

          if (options.display_y_grid) {
            for (var j = 0; j <= 1; j++) {
              var t = (j === 1 ? offset_y + (y_spacing / 2) : offset_y);
              this.path(["M", offset_x, t, "H", options.width - 5]).attr({'stroke': options.grid_color}).toBack();

              if (display === 1 && j === 1) {
                /*
                * TODO: There should be a better way to draw this last line.
                *       The math here draws a line above itself and on the display line.
                *       This kills the outlier.
                */
                this.path(["M", offset_x, offset_y - (y_spacing / 2), "H", options.width - 5]).attr({'stroke': options.grid_color}).toBack();
              }
            }
          }

          this.text(offset_x, offset_y, displayValue(Math.round(scale), 0)).attr({
            'fill': options.text_date['fill'],
            'font-weight': 'bold'
          }).toFront();
        }

        offset_y -= y_spacing;
        display--;
      }
    };

    Raphael.fn.drawChart = function(X, Y) {
      var line_paths = [];
      var dates = _(data).keys();
      var values = _(data).values();
      var margin_left = options.margin_left;
      var margin_bottom = options.margin_bottom;
      var margin_top = options.margin_top;
      var stroke_width = dates.length > 45 ? options.stroke_width_dense : options.stroke_width;

      for (var k = 0, kk = values[0].length; k < kk; k++) {
        line_paths[k] = this.path().attr({
          'stroke': options.line_colors[k],
          'stroke-width': stroke_width,
          'stroke-linejoin': 'round'
        });
      }

      var layer = this.set();
      var point_array = [];
      var values_array = [];
      var tooltip_visible = false;
      var leave_timer = null;
      var dates_length = dates.length;

      for (var i = 0; i < dates_length; i++) {
        var x = Math.round(X * i) + (options.label_offset + 15);

        point_array[x] = [];
        values_array[x] = [];

        var stroke_color = '#fff';
        var point_size = options.point_size;
        var point_size_hover = options.point_size_hover;
        var first_point = i === 0;

        if (dates_length > 45 && dates_length <= 90) {
          point_size = 3;
          point_size_hover = 5;
        } else if (dates_length > 90) {
          point_size = 0;
          point_size_hover = 3;
        }

        for (var j = 0; j < values[i].length; j++) {
          var value = values[i][j];
          var y = Math.round(options.height - margin_bottom - Y * value);

          if (value < 0) {
            y = Math.round(options.height - margin_bottom - Y * 0);
          }

          if (dates_length <= 45) {
            line_paths[j][(first_point ? 'moveTo' : 'cplineTo')](x, y, 10);
          } else if (dates_length <= 90) {
            line_paths[j][(first_point ? 'moveTo' : 'cplineTo')](x, y, 4);
          } else {
            line_paths[j][(first_point ? 'moveTo' : 'cplineTo')](x, y, 1);
          }

          var point = this.circle(x, y, point_size).attr({
            fill: options.line_colors[j],
            stroke: stroke_color
          });

          point.insertAfter(line_paths[j]);
          point_array[x].push(point);
          values_array[x].push(value);
        }

        layer.push(this.rect(x, 0, X, options.height - margin_bottom).attr({
          'stroke': 'none',
          'fill': '#fff',
          'opacity': 0
        }));

        (function(rect, points, x, values) {
          rect.hover(function() {
            _.each(points[x], function(point) {
              point.attr({
                'r': point_size_hover
              });
            });
          },
          function() {
            _.each(points[x], function(point) {
              point.attr({
                'r': point_size
              });
            });
            $('#tooltip').hide();
          }).mousemove(function(event) {
            if(options.enable_tooltips) {
              tooltip(event, values[x]);
            }
          });
        })(layer[layer.length - 1], point_array, x, values_array);
      }
    };

    return {
      init: function(target_, data_, options_) {
        $.extend(true, options, options_);

        chart = $(target_);
        chart.children().remove();
        data = data_;

        var i = data.length;

        while (i--) {
          data[i] = parseDate(data[i]);
        }

        r = Raphael(chart.get(0), options.width, options.height);
      },
      render: function() {
        var max;
        var dates = _(data).keys();
        var values = _(data).values();

        if (_.isArray(values[0])) {
          max = _(_(values).flatten()).max();
        } else {
          max = _(values).max();

          _.each(data, function(value, key) {
            data[key] = [value];
          });
        }

        var X = (options.width - (options.label_offset + 15)) / dates.length;
        var Y = (options.height - options.margin_bottom - options.margin_top) / max;

        r.drawXAxis(dates, X);
        r.drawChart(X, Y);
        r.drawYAxis(max);
      }
    };
  };

  $.delorean = function(target, data, options) {
    var delorean = new Delorean();
    delorean.init(target, data, options);
    return delorean;
  };

})(jQuery, this, this.document);
