// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require moment
//= require moment-timezone-with-data
//= require bootstrap-datetimepicker
//= require jquery.validate
//= require jquery.validate.additional-methods
//= require select2/select2.full
//= require jquery-tablesorter
//= require_self
//= require nuntius/reports

var DATE_FORMAT = 'DD/MM/YYYY';
var DATETIME_FORMAT = 'DD/MM/YYYY HH:mm';

(function() {

  $.validator.addMethod('date', function(value, element) {
    return this.optional( element ) || moment(value, DATE_FORMAT, true).isValid();
  });

  $.validator.addMethod('datetime', function(value, element) {
    return this.optional( element ) || moment(value, DATETIME_FORMAT, true).isValid();
  });

})();
