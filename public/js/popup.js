var popupStatus = 0; // Disabled

// Take the user to the top of the page
function toTop() {
    $('html,body').animate(
        {scrollTop: 0},
        {
            easing: 'swing',
            queue: false,
            complete: function(){ // Callback so we finish scrolling first
                showPopup();
            }
        }
    );
}

// Show the popup
function showPopup(){
    if (popupStatus === 0){
        $("#popup-hidden").css({
            "opacity": "0.7"
        });
        $("#popup-hidden").fadeIn("slow");
        $("#popup-visible").fadeIn("slow");
        popupStatus = 1;
    }
}

// Close the popup
function closePopup(){
    if (popupStatus == 1){
        $("#popup-hidden").fadeOut("slow");
        $("#popup-visible").fadeOut("slow");
        popupStatus = 0;
    }
}

// Center the popup on the browser window
function centrePopup(){
    // Get your data...
    var windowWidth = document.documentElement.clientWidth;
    var windowHeight = document.documentElement.clientHeight;

    var popupWidth = $("#popup-visible").width();
    var popupHeight = $("#popup-visible").height();

    // Use it!
    $("#popup-visible").css({
        "position": "absolute",
        "top": windowHeight/2 - popupHeight/2,
        "left": windowWidth/2 - popupWidth/2
    });

    // Force it for IE6
    $("#popup-hidden").css({
        "height": windowHeight,
        "width": windowWidth
    });
}

// onLoad
$(document).ready(function(){
    // Scroll to top; show the popup
    $("#popup-button").click(function(){
        toTop(); // Will call showPopup() via callback
        centrePopup();
    });

    // Close the popup...
    // ...by clicking the X
    $("#popup-close").click(function(){
        closePopup();
    });
    // ...by clicking outside the popup
    $("#popup-hidden").click(function(){
        closePopup();
    });
    // ...by hitting ESC
    $(document).keypress(function (e){
        if (e.keyCode == 27){
            closePopup();
        }
    });
});
