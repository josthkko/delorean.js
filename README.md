= delorean.js

Delorean.js is a charting library for time-based graphs utilizing SVG through Raphael.js

You can see a live demo: http://deloreanjs.heroku.com

== Motivations

Raphael.js is a very powerful SVG library. The maintainer of Raphael has made an
attempt at building a graphing library called g.Raphael but it lacks documentation.
I built this library in order to build SVG-based time series graphs for the various
reporting tools that I work on. The goal of this library is to be extremely flexible with
charting time series data and will not grow beyond that. The reason is that I believe
too many charting libraries today try to do every graph out there and instead fall short on
all of them.

== Features

* Graph can visually scale from 7 days to 6 months of data (7 to 180 points)
* Support for multiple plot lines
* Aggregate point support for each date (highlight all values for a given date)
* Options can be passed in to modify all visual aspects (WIP)
* Tool tips (WIP)

== Requirements

This library depends on the following:

* jQuery (~> 1.4+)
* Raphael.js (~> 1.5.2+) with raphael.path.methods.js (in the Raphael repo)
* Underscore.js (~> 1.1.3)
* strftime.js (included in this project)
 
== Basic Usage

  // application.js
  
  (function($) {
    
    $(document).ready(function(){

      $.getJSON('/stats?sequence_length=7', function(stats) {
        var chart = $.delorean('#week_chart', stats, {});
        chart.render();
      });

      $.getJSON('/stats?sequence_length=30', function(stats) {
        var chart = $.delorean('#month_chart', stats, {});
        chart.render();
      });

      $.getJSON('/stats?sequence_length=90', function(stats) {
        var chart = $.delorean('#quarter_chart', stats, {});
        chart.render();
      });

      $.getJSON('/stats?sequence_length=180', function(stats) {
        var chart = $.delorean('#semiannual_chart', stats, {});
        chart.render();
      });

    });
    
  })(jQuery);

== Data Format

Delorean.js currently accepts two data formats.

*NOTE* You must ensure that your date values at consistent intervals.


Single Line:

  {
    "2011-10-08T09:30:00Z": 890234,
    "2010-12-31T09:30:00Z": 590234,
    "2010-12-30T09:30:00Z": 3024,
    "2010-12-29T09:30:00Z": 29134,
    "2010-12-28T09:30:00Z": 82372,
    ....
  }

Multiple Lines:

  {
    "2011-10-08T09:30:00Z": [890234, 283749],
    "2010-12-31T09:30:00Z": [590234, 827],
    "2010-12-30T09:30:00Z": [3024, null],
    "2010-12-29T09:30:00Z": [29134, 9827],
    "2010-12-28T09:30:00Z": [82372, 132],
    ....
  }

To associate names you just need to set the line_labels options:

  $.delorean('#chart', {...data...}, {line_labels: ['Reads','Writes']});


== Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with version or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

== Copyright

Delorean.js - a time-based javascript charting library

Author:: Justin Smestad (<justin.smestad@gmail.com>)
Copyright:: Copyright (c) 2010, 2011 Justin Smestad
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


