/***************************/
// layout functions
// author: Abigail Cabunoc
// abigail.cabunoc@oicr.on.ca      
/***************************/

//The layout methods

    function columns(leftWidth, rightWidth, noUpdate){
      $("#widget-holder").children(".left").css("width",leftWidth + "%");
      if(rightWidth==0){rightWidth=100;}
      $("#widget-holder").children(".right").css("width",rightWidth + "%");
      if(!noUpdate){ updateLayout(); }
    }

    function deleteLayout(layout){
      var class = $("#widget-holder").attr("class");
      $.get("/rest/layout/" + class + "/" + layout + "?delete=1");
      $("div.columns ul div li#layout-" + layout).remove();
    }

    function setLayout(layout){
      var class = $("#widget-holder").attr("class");
      $.get("/rest/layout/" + class + "/" + layout, function(data) {
          var nodeList = data.childNodes[0].childNodes;
          var len = nodeList.length;
          for(i=0; i<len; i++){
            var node = nodeList.item(i);
            if(node.nodeName == "data"){
              var leftList = node.attributes.getNamedItem('left').nodeValue.split(',');
              var rightList = node.attributes.getNamedItem('right').nodeValue.split(',');
              var leftWidth = node.attributes.getNamedItem('leftWidth').nodeValue;
              resetLayout(leftList, rightList, leftWidth);
            }
          }
        }, "xml");
    }

    function newLayout(layout){
      updateLayout(layout);
    $(".list-layouts").load("/rest/layout_list/" + $(".list-layouts").attr("type"), function(response, status, xhr) {
//         $("#layout-input").focus(); 
//           $("div.columns ul").show().delay(3000).hide();
         if (status == "error") {
            var msg = "Sorry but there was an error: ";
            $(".list-layouts").html(msg + xhr.status + " " + xhr.statusText);
          }
        });
      return false;
    }

    function updateLayout(layout){
      l = 'default';
      if((typeof layout) == 'string'){
        l = escape(layout); 
      }
      var holder =  $("#widget-holder");
      var class = holder.attr("class");
      var left = holder.children(".left").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var right = holder.children(".right").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var leftWidth = getLeftWidth(holder);
      $.post("/rest/layout/" + class + "/" + l, { 'left[]': left, 'right[]' : right, 'leftWidth':leftWidth });
    }

    function getLeftWidth(holder){
      var totWidth = parseFloat(holder.css("width"));
//       var leftWidth = parseFloat(holder.children(".left").css("width"));
      var leftWidth = (parseFloat(holder.children(".left").css("width"))/totWidth)*100;
      return leftWidth
    }

    function resetLayout(leftList, rightList, leftWidth){
      $("div#navigation").children("ul").children("li").removeClass("ui-selected");
      $("#widget-holder").children().children("li").removeClass("visible");
      $("div#navigation").children("ul").children("li").children("span.ui-icon").remove();

      columns(leftWidth, (100-leftWidth), 1);
      for(widget in leftList){
        var widget_name = leftList[widget];
        if(widget_name.length > 0){
          var nav = $("#nav-" + widget_name);
          var content = "div#" + widget_name + "-content";
          nav.attr("load", 0);
          openWidget(widget_name, nav, content, ".left");
        }
      }
      for(widget in rightList){
        var widget_name = rightList[widget];
        if(widget_name.length > 0){
          var nav = $("#nav-" + widget_name);
          var content = "div#" + widget_name + "-content";
          openWidget(widget_name, nav, content, ".right");
        }
      }
      updateLayout();
    }
