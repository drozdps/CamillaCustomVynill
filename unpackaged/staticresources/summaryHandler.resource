        var checkedSum =parseFloat('{!trackLength}');
        var countChecked ='{!trackCount}';
        var out=document.getElementById("displayCount1");
        out.innerHTML=countChecked;
        var outSum=document.getElementById("displayLength1");
        outSum.innerHTML=checkedSum.toFixed(2);
        var outRemainingTracks = document.getElementById("displayRemainingTracks1");
        outRemainingTracks.innerHTML=20-countChecked;
        var outRemainingLength = document.getElementById("displayRemainingLength1");
        outRemainingLength.innerHTML=(parseFloat(90.00)-checkedSum);
        function calc(length,me){
            if(me.checked)
            {
                countChecked++;
                checkedSum+=length;
            }
            else
            {
               countChecked--; 
               checkedSum-=length
            }      
            var out=document.getElementById("displayCount1");
            out.innerHTML=countChecked;
            var outSum=document.getElementById("displayLength1");
            outSum.innerHTML=checkedSum.toFixed(2);
            var outRemainingTracks = document.getElementById("displayRemainingTracks1");
            outRemainingTracks.innerHTML=20-countChecked;
            var outRemainingLength = document.getElementById("displayRemainingLength1");
            outRemainingLength.innerHTML=(parseFloat(90.00)-checkedSum);             
        };
