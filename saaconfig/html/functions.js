function isBlank(s) {
        if (s == "") return true;                                                       for (var i = 0; i < s.length; i++) {
                var c = s.charAt(i);
                if ((c != ' ') && (c != '\n') && (c != '\t')) return false;
        }       
        return true;
}                         
