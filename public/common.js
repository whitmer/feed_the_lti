var $primary_feeds = $("#feeds");
var $secondary_feeds = $("#secondary_feeds");
var $entries = $("#entries");
var feeds = {
  feeds: {},
  loadEntries: function(url, selection, $feeds) {
    $("#more").hide();
    $.getJSON(url, function(data) {
      if(!data.objects) { 
        alert("Error!");
        return;
      }
      if(data.feeds) {
        for(var jdx in data.feeds) {
          feeds.updateFeed(data.feeds[jdx], $feeds);
        }
      }
      for(var idx = 0; idx < data.objects.length; idx++) {
        (function() {
          var entry = data.objects[idx];
          var $entry = $(Handlebars.templates['feed_entry'](entry));
          $entry.click(function(event) {
            if($(event.target).closest("a.feed_link").length > 0) {
              if(feeds.selectEntry(entry)) {
                event.preventDefault();
              }
            }
          });
          $entries.append($entry);
        })();
      }
      if(data.meta && data.meta.next) {
        $("#more").show().attr('rel', data.meta.next);
      }
      if(data.objects.length == 0) {
        $("#more_entries").click();
      }
    });
  },
  reloadEntries: function(url, $feeds) {
    $entries.empty();
    feeds.loadEntries(url, false, $feeds);
  },
  updateFeed: function(feed, $feeds, $old_feed) {
    if(!$feeds) { debugger; }
    var $feed = $(Handlebars.templates['feed'](feed));
    if(feeds.currentFeed && feed.id == feeds.currentFeed.id) {
      $feed.addClass('active');
    }
    $feed.click(function(event) {
      event.preventDefault();
      feeds.selectFeed(feed, $feed, $feeds);
    });
    var reload = !!$old_feed;
    if(!$old_feed) {
      $old_feed = feeds.feeds[feed.id] && feeds.feeds[feed.id].elem;
    }
    feeds.feeds[feed.id] = {
      data: feed,
      elem: $feed
    };
    if($old_feed) {
      $old_feed.after($feed);
      $old_feed.remove();
      if(reload) {
        $feed.click();
      }
    } else {
      $feeds.append($feed);
    }
  },
  loadFeeds: function(url, $feeds, include_root) {
    if(include_root) {
      var count = $feeds.attr('data-count');
      var name = $feeds.attr('data-title');
      var feed = {name: name, id: "all" + $feeds.attr('id'), raw_id: "all", selected: $feeds.attr('id') == 'feeds', header: true};
      feeds.updateFeed(feed, $feeds);
    }
    $.getJSON(url, function(data) {
      if(!data.objects) { 
        alert("Error!");
        return;
      }
      for(var idx = 0; idx < data.objects.length; idx++) {
        (function() {
          var feed = data.objects[idx];
          feeds.updateFeed(feed, $feeds);
        })();
      }
      if(data.meta && data.meta.next) {
        feeds.loadFeeds(data.meta.next, $feeds);
      }
    });
  },
  selectFeed: function(feed, $feed, $feeds) {
    $("#all_feeds li.active").removeClass('active');
    $feed.addClass('active');
    $("#feed_summary").remove()
    if(feed.raw_id != 'all') {
      feed.admin = 
      $("h2").after(Handlebars.templates['feed_summary'](feed));
    }
    if($feeds.hasClass('addable')) {
      $("#feed_summary").addClass('addable');
    }
    $("#feed_summary").toggleClass('deletable', $feeds.hasClass('deletable'));
    feeds.reloadEntries("/api/v1/" + $feeds.attr('rel') + "/entries.json?feed_id=" + (feed.raw_id || feed.id), $feeds);
    feeds.currentFeed = feed;
  },
  refreshCurrentFeed: function() {
    if(!feeds.currentFeed || feeds.currentFeed.id == 'all') { return; }
    $.ajax({
      type: 'POST',
      dataType: 'json',
      url: "/api/v1/feeds/" + feeds.currentFeed.raw_feed_id + "/" + feeds.currentFeed.nonce + ".json",
      success: function(data) {
        feeds.feeds[feeds.currentFeed.id].elem.click();
      },
      error: function() {
        alert("Error!");
      }
    });
  },
  deleteCurrentFeed: function() {
    var response = confirm("Are you sure you want to delete this feed?");
    if(!response) { return; }
    var $feeds = feeds.feeds[feeds.currentFeed.id].elem.closest('ul');
    $.ajax({
      type: 'POST',
      data: {
        '_method': 'DELETE'
      },
      dataType: 'json',
      url: "/api/v1/" + $feeds.attr('rel') + "/feeds/" + feeds.currentFeed.id + ".json",
      success: function(data) {
        feeds.feeds[feeds.currentFeed.id].elem.remove();
        $feeds.find(".feed:first").click();
      },
      error: function() {
        alert("Error!");
      }
    });
    
  },
  allowStudentFeeds: function(allow) {
    var url = "/api/v1/" + $primary_feeds.attr('rel') + ".json";
    $.ajax({
      type: 'POST',
      data: {
        '_method': 'PUT', 
        'allow_student_feeds': (allow ? "1" : "0")
      },
      dataType: 'json',
      url: url,
      success: function(data) {
      },
      error: function() {
        alert("Error!");
      }
    });
  },
  selectEntry: function(entry) {
    if(feeds.selectionMode) {
      alert("LTI embed!");
      var return_url = $("#entries").attr('rel');
      console.log(entry);
      return true;
    } else {
      return false;
    }
  },
  addFeed: function(feed_url, filter, endpoint) {
    $("#add_feed").attr('disabled', true).addClass('disabled');
    $.ajax({
      type: 'POST',
      dataType: 'json',
      url: endpoint,
      data: {
        url: feed_url,
        filter: filter
      },
      success: function(data) {
        $("#add_feed").attr('disabled', false).removeClass('disabled');
        if(!data) {
          alert("Feed failed to add. Please make sure it's a valid feed.");
          return;
        }
        feeds.updateFeed(data, $primary_feeds);
        if(!data.callback_enabled) {
          alert("Feed added, but no callback hub found. Entries will have to be refreshed by hand");
        }
        feeds.feeds[data.id].elem.click();
      },
      error: function() {
        alert("Error!");
        $("#add_feed").attr('disabled', false).removeClass('disabled');
      }
    });
  },
  pingOldestFeed: function() {
    $.ajax({
      type: 'POST',
      dataType: 'json',
      url: "/api/v1/feeds/next.json",
      success: function(data) {
        $primary_feeds.find(".feed:first").click();
      },
      error: function() {
      }
    });
  }
}
$(document).ready(function() {
  feeds.selectionMode = $entries.hasClass('selection_mode');
  feeds.pingOldestFeed();
  if($primary_feeds.length) {
    feeds.loadFeeds("/api/v1/" + $primary_feeds.attr('rel') + "/feeds.json", $primary_feeds, true);
  }
  $("#load_secondary_feeds").click(function(event) {
    event.preventDefault();
    var path = "/api/v1/" + $secondary_feeds.attr('rel') + "/feeds.json";
    feeds.loadFeeds(path, $secondary_feeds, true);
    $(this).hide();
  });
  
  $(document).on('click', "#refresh_feed", function(event) {
    event.preventDefault();
    feeds.refreshCurrentFeed();
  });
  $(document).on('click', "#delete_feed", function(event) {
    event.preventDefault();
    feeds.deleteCurrentFeed();
  });
  $("#add_feed").click(function() {
    var url = $("#feed_url").val();
    var filter = $("#feed_filter").val() || "";
    feeds.addFeed(url, filter, "/api/v1/" + $primary_feeds.attr('rel') + "/feeds.json");
  });
  $(document).on('click', "#add_to_feeds", function() {
    feeds.addFeed(feeds.currentFeed.feed_url, feeds.currentFeed.filter, "/api/v1/" + $primary_feeds.attr('rel') + "/feeds.json");
  });
  $("#more_entries").click(function(event) {
    event.preventDefault();
    $(this).blur();
    var $feeds = feeds.feeds[feeds.currentFeed.id].elem.closest('ul');
    feeds.loadEntries($("#more").attr('rel'), false, $feeds);
  });
  $("#allow_student_feeds").change(function() {
    feeds.allowStudentFeeds($(this).attr('checked'));
  });
});

// lib/handlebars/base.js
var Handlebars = {};

Handlebars.VERSION = "1.0.beta.2";

Handlebars.helpers  = {};
Handlebars.partials = {};

Handlebars.registerHelper = function(name, fn, inverse) {
  if(inverse) { fn.not = inverse; }
  this.helpers[name] = fn;
};

Handlebars.registerPartial = function(name, str) {
  this.partials[name] = str;
};

Handlebars.registerHelper('helperMissing', function(arg) {
  if(arguments.length === 2) {
    return undefined;
  } else {
    throw new Error("Could not find property '" + arg + "'");
  }
});

Handlebars.registerHelper('blockHelperMissing', function(context, options) {
  var inverse = options.inverse || function() {}, fn = options.fn;


  var ret = "";
  var type = Object.prototype.toString.call(context);

  if(type === "[object Function]") {
    context = context();
  }

  if(context === true) {
    return fn(this);
  } else if(context === false || context == null) {
    return inverse(this);
  } else if(type === "[object Array]") {
    if(context.length > 0) {
      for(var i=0, j=context.length; i<j; i++) {
        ret = ret + fn(context[i]);
      }
    } else {
      ret = inverse(this);
    }
    return ret;
  } else {
    return fn(context);
  }
});

Handlebars.registerHelper('each', function(context, options) {
  var fn = options.fn, inverse = options.inverse;
  var ret = "";

  if(context && context.length > 0) {
    for(var i=0, j=context.length; i<j; i++) {
      ret = ret + fn(context[i]);
    }
  } else {
    ret = inverse(this);
  }
  return ret;
});

Handlebars.registerHelper('if', function(context, options) {
  if(!context || Handlebars.Utils.isEmpty(context)) {
    return options.inverse(this);
  } else {
    return options.fn(this);
  }
});

Handlebars.registerHelper('unless', function(context, options) {
  var fn = options.fn, inverse = options.inverse;
  options.fn = inverse;
  options.inverse = fn;

  return Handlebars.helpers['if'].call(this, context, options);
});

Handlebars.registerHelper('with', function(context, options) {
  return options.fn(context);
});
;
// lib/handlebars/utils.js
Handlebars.Exception = function(message) {
  var tmp = Error.prototype.constructor.apply(this, arguments);

  for (var p in tmp) {
    if (tmp.hasOwnProperty(p)) { this[p] = tmp[p]; }
  }
};
Handlebars.Exception.prototype = new Error;

// Build out our basic SafeString type
Handlebars.SafeString = function(string) {
  this.string = string;
};
Handlebars.SafeString.prototype.toString = function() {
  return this.string.toString();
};

(function() {
  var escape = {
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#x27;",
    "`": "&#x60;"
  };

  var badChars = /&(?!\w+;)|[<>"'`]/g;
  var possible = /[&<>"'`]/;

  var escapeChar = function(chr) {
    return escape[chr] || "&amp;";
  };

  Handlebars.Utils = {
    escapeExpression: function(string) {
      // don't escape SafeStrings, since they're already safe
      if (string instanceof Handlebars.SafeString) {
        return string.toString();
      } else if (string == null || string === false) {
        return "";
      }

      if(!possible.test(string)) { return string; }
      return string.replace(badChars, escapeChar);
    },

    isEmpty: function(value) {
      if (typeof value === "undefined") {
        return true;
      } else if (value === null) {
        return true;
      } else if (value === false) {
        return true;
      } else if(Object.prototype.toString.call(value) === "[object Array]" && value.length === 0) {
        return true;
      } else {
        return false;
      }
    }
  };
})();;
// lib/handlebars/vm.js
Handlebars.VM = {
  template: function(templateSpec) {
    // Just add water
    var container = {
      escapeExpression: Handlebars.Utils.escapeExpression,
      invokePartial: Handlebars.VM.invokePartial,
      programs: [],
      program: function(i, fn, data) {
        var programWrapper = this.programs[i];
        if(data) {
          return Handlebars.VM.program(fn, data);
        } else if(programWrapper) {
          return programWrapper;
        } else {
          programWrapper = this.programs[i] = Handlebars.VM.program(fn);
          return programWrapper;
        }
      },
      programWithDepth: Handlebars.VM.programWithDepth,
      noop: Handlebars.VM.noop
    };

    return function(context, options) {
      options = options || {};
      return templateSpec.call(container, Handlebars, context, options.helpers, options.partials, options.data);
    };
  },

  programWithDepth: function(fn, data, $depth) {
    var args = Array.prototype.slice.call(arguments, 2);

    return function(context, options) {
      options = options || {};

      return fn.apply(this, [context, options.data || data].concat(args));
    };
  },
  program: function(fn, data) {
    return function(context, options) {
      options = options || {};

      return fn(context, options.data || data);
    };
  },
  noop: function() { return ""; },
  invokePartial: function(partial, name, context, helpers, partials) {
    if(partial === undefined) {
      throw new Handlebars.Exception("The partial " + name + " could not be found");
    } else if(partial instanceof Function) {
      return partial(context, {helpers: helpers, partials: partials});
    } else if (!Handlebars.compile) {
      throw new Handlebars.Exception("The partial " + name + " could not be compiled when running in vm mode");
    } else {
      partials[name] = Handlebars.compile(partial);
      return partials[name](context, {helpers: helpers, partials: partials});
    }
  }
};

Handlebars.template = Handlebars.VM.template;

// Handlebars templates
(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['feed'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, foundHelper, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  
  return "active";}

function program3(depth0,data) {
  
  
  return "header";}

function program5(depth0,data) {
  
  var buffer = "", stack1, stack2;
  buffer += "\n      ";
  foundHelper = helpers.filter;
  stack1 = foundHelper || depth0.filter;
  stack2 = helpers['if'];
  tmp1 = self.program(6, program6, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.program(8, program8, data);
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    ";
  return buffer;}
function program6(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        <span class=\"count\">filtered ";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " entries by \"";
  foundHelper = helpers.filter;
  stack1 = foundHelper || depth0.filter;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "filter", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\"</span>\n      ";
  return buffer;}

function program8(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        <span class=\"count\">";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " entries</span>\n      ";
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
  buffer += " ";
  foundHelper = helpers.header;
  stack1 = foundHelper || depth0.header;
  stack2 = helpers['if'];
  tmp1 = self.program(3, program3, data);
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
  tmp1 = self.program(5, program5, data);
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
  buffer += escapeExpression(stack1) + "\" target=\"_blank\" class='entry_link'>";
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
  buffer += "\n    </div>\n    <div class='feed_name'>\n      ";
  foundHelper = helpers.feed_name;
  stack1 = foundHelper || depth0.feed_name;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "feed_name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\n    </div>\n    <div class=\"created\">\n      ";
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
  
  var buffer = "", stack1;
  buffer += "\n    <div class=\"filter\">filtered ";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " entries by \"";
  foundHelper = helpers.filter;
  stack1 = foundHelper || depth0.filter;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "filter", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\"</div>\n  ";
  return buffer;}

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n    <span class=\"posts\">";
  foundHelper = helpers.entry_count;
  stack1 = foundHelper || depth0.entry_count;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "entry_count", { hash: {} }); }
  buffer += escapeExpression(stack1) + " entries</span>\n  ";
  return buffer;}

function program5(depth0,data) {
  
  
  return "auto-update ";}

  buffer += "<div id=\"feed_summary\">\n  ";
  foundHelper = helpers.filter;
  stack1 = foundHelper || depth0.filter;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.program(3, program3, data);
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  <span class=\"last_checked\">";
  foundHelper = helpers.callback_enabled;
  stack1 = foundHelper || depth0.callback_enabled;
  stack2 = helpers['if'];
  tmp1 = self.program(5, program5, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "checked ";
  foundHelper = helpers.last_checked;
  stack1 = foundHelper || depth0.last_checked;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "last_checked", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span>\n  <span class=\"links\">\n    <a href=\"#\" id=\"refresh_feed\">Refresh</a>&nbsp;&nbsp;\n    <a href=\"";
  foundHelper = helpers.feed_url;
  stack1 = foundHelper || depth0.feed_url;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "feed_url", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" target=\"_blank\">Source</a>&nbsp;&nbsp;\n    <a href=\"#\" id=\"delete_feed\">Delete</a>\n  </span>\n  <div id=\"add_to_feeds_holder\">\n    <button class='btn btn-primary' id='add_to_feeds'>Add to course feeds</button>\n  </div>\n</div>\n";
  return buffer;});
})();
