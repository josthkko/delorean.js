// application.js

(function($) {

  $(document).ready(function(){

    $.getJSON('data.htm', function(stats) {
      var chart = $.delorean('#my_chart', stats, {height: 400, enable_tooltips: true, line_labels: ['Total', 'Reads'], margin_bottom: 20, label_display_count: 6,label_offset: 100});
 
      chart.render();
    });

  });

})(jQuery);
