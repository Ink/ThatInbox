function getHTMLElementsAtPoint(x,y) {
    var tags = ",";
    var e = document.elementFromPoint(x,y);
    while (e) {
        if (e.tagName) {
            tags += e.tagName + ',';
        }
        e = e.parentNode;
    }
    return tags;
}

function getLinkSRCAtPoint(x,y) {
    var tags = "";
    var e = document.elementFromPoint(x,y);
    while (e) {
        if (e.src) {
            tags += e.src;
            break;
        }
        e = e.parentNode;
    }
    return tags;
}

function getObjectIdAtPoint(x,y) {
    var tags = "";
    var e = document.elementFromPoint(x,y);
    while (e) {
        if (e.id) {
            tags += e.id;
            break;
        }
        e = e.parentNode;
    }
    return tags;
}

function getLinkHREFAtPoint(x,y) {
    var tags = "";
    var e = document.elementFromPoint(x,y);
    while (e) {
        if (e.href) {
            tags += e.href;
            break;
        }
        e = e.parentNode;
    }
    return tags;
}
