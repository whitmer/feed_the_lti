(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['feed'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, foundHelper, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  
  return "active";}

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n      <span class=\"count\">";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " entries</span>\n    ";
  return buffer;}

  buffer += "<li class=\"feed ";
  foundHelper = helpers.selected;
  stack1 = foundHelper || depth0.selected;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\">\n  <a href=\"#\">";
  foundHelper = helpers.name;
  stack1 = foundHelper || depth0.name;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\n    ";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  stack2 = helpers['if'];
  tmp1 = self.program(3, program3, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </a>\n</li>";
  return buffer;});
templates['feed_entry'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, foundHelper, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        <a href=\"mailto:";
  foundHelper = helpers.author_email;
  stack1 = foundHelper || depth0.author_email;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "author_email", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">";
  foundHelper = helpers.author_name;
  stack1 = foundHelper || depth0.author_name;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "author_name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</a>\n      ";
  return buffer;}

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        ";
  foundHelper = helpers.author_name;
  stack1 = foundHelper || depth0.author_name;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "author_name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\n      ";
  return buffer;}

  buffer += "<div class=\"entry\">\n  <h3><a href=\"";
  foundHelper = helpers.url;
  stack1 = foundHelper || depth0.url;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "url", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" target=\"_blank\">";
  foundHelper = helpers.title;
  stack1 = foundHelper || depth0.title;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "title", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</a></h3>\n  <div class='content'>\n    <div class='author'>\n      ";
  foundHelper = helpers.author_email;
  stack1 = foundHelper || depth0.author_email;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.program(3, program3, data);
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    </div>\n    <div class=\"created\">\n      ";
  foundHelper = helpers.created;
  stack1 = foundHelper || depth0.created;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "created", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\n    </div>\n    <div class=\"clear\"></div>\n    ";
  foundHelper = helpers.short_html;
  stack1 = foundHelper || depth0.short_html;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "short_html", { hash: {} }); }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </div>\n</div>";
  return buffer;});
templates['feed_summary'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, foundHelper, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  
  return "auto-update";}

function program3(depth0,data) {
  
  
  return "\n      <a href=\"#\" id=\"delete_feed\">Delete</a>\n    ";}

  buffer += "<div id=\"feed_summary\">\n  <span class=\"posts\">";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " posts</span>\n  <span class=\"auto_update\">";
  foundHelper = helpers.callback_enabled;
  stack1 = foundHelper || depth0.callback_enabled;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</span>\n  <span class=\"last_checked\">last checked ";
  foundHelper = helpers.last_checked;
  stack1 = foundHelper || depth0.last_checked;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "last_checked", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span>\n  <span class=\"links\">\n    <a href=\"#\" id=\"refresh_feed\">Refresh</a>\n    ";
  foundHelper = helpers.admin;
  stack1 = foundHelper || depth0.admin;
  stack2 = helpers['if'];
  tmp1 = self.program(3, program3, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </span>\n</div>";
  return buffer;});
})();