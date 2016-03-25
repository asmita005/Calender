<%@ page import="com.ot.gs.cda.templating.util.CDAUtil" %>
<%@ page import="com.ot.gs.cda.templating.util.TemplatingConstants" %>
<%@ page import="com.vignette.as.client.javabean.ManagedObject" %>
<%@ page import="com.vignette.ext.templating.util.PageUtil" %>
<%@ page import="com.vignette.ext.templating.util.RequestContext" %>
<%@ page import="com.vignette.ext.templating.util.XSLPageUtil" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ taglib uri="/WEB-INF/vgnExtTemplating.tld" prefix="templating" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="../include/include.jsp"%>


      
  	

<%
    try{
        long sTime = System.currentTimeMillis();
        final  String DURATION = " days duration ";
        final  String RECURRING = " (recurring) ";
        final String FULL_DAY = "(Full day)";
        final String NO_END_TIME = "(No end time)";
        final String NO_START_TIME = "(No start time)";
        RequestContext rc = PageUtil.getCurrentRequestContext(pageContext);
        String linkUrl = XSLPageUtil.buildLinkURI(rc, rc.getRequestOIDString(), null, rc.getFormat());
        SimpleDateFormat sdf = new SimpleDateFormat("MMMM yyyy");
        Calendar calToday = Calendar.getInstance();
        Calendar calTempCal = (Calendar) calToday.clone();
        HashMap<String,Integer> recurEventsMap = new HashMap<String,Integer>();
        HashMap<String,Integer> displayedDurationEvents = new HashMap<String,Integer>();
        String previousDate = "";        
        String eventCategories;
        String eventText;
        String caseSensitive;
        int targetYear = 0;
        int targetMonth = 0;
        int targetDay = 0;
	 	String sDate ="";
        String displayMode; //default Month view
        String styleMode; //default Block view
        int timePlanWidth = 0;
        int timePlanStartHour = 0;
        int timePlanBlockSize = 0;
        int timePlanEndHour = 0;
        eventCategories = request.getParameter("eventCategories") != null?request.getParameter("eventCategories"):"";
        eventText = request.getParameter("eventText") != null?request.getParameter("eventText"):"";
        caseSensitive = request.getParameter("caseSensitive") != null?request.getParameter("caseSensitive"):"";
        try{
            targetYear = request.getParameter("targetYear") != null? Integer.parseInt(request.getParameter("targetYear").trim()):0;
            targetMonth = request.getParameter("targetMonth") != null? Integer.parseInt(request.getParameter("targetMonth").trim()):0;
            targetDay = request.getParameter("targetDay") != null? Integer.parseInt(request.getParameter("targetDay").trim()):0;
            
        }catch(Exception ex){
            System.out.println("Exception occurred");
            targetMonth = 0;
            targetYear = 0;
        }
        if (targetYear == 0 && targetMonth == 0) {
            targetYear = calToday.get(Calendar.YEAR);
            targetMonth = calToday.get(Calendar.MONTH);
        }
        displayMode = request.getParameter("displayMode") != null?request.getParameter("displayMode"):"M";
        styleMode = request.getParameter("styleMode") != null ? request.getParameter("styleMode"):"B";

        System.out.println("Target Year::"+targetYear+" Target Month::"+targetMonth+" Target Day::"+targetDay);


        if ("T".equals(styleMode)){//if style mode is TimePlan, then displayMode must be either D or W
            if ("M".equals(displayMode)){
                displayMode = "W";
            }
            timePlanWidth = request.getParameter("timePlanWidth") != null? Integer.parseInt(request.getParameter("timePlanWidth")):8;
            timePlanStartHour = request.getParameter("timePlanStartHour") != null?Integer.parseInt(request.getParameter("timePlanStartHour")):9;
            timePlanBlockSize = request.getParameter("timePlanBlockSize") != null?Integer.parseInt(request.getParameter("timePlanBlockSize")):1;
            timePlanEndHour = ((timePlanWidth + timePlanStartHour) > 23)?23:((timePlanWidth+timePlanStartHour)-1); 
            System.out.println("timePlanWidth::"+timePlanWidth+" timePlanStartHour::"+timePlanStartHour
                    +" timePlanEndHour "+timePlanEndHour+" timePlanBlockSize::"+timePlanBlockSize);
        }
        
        System.out.println("Display Mode::"+displayMode+" style::"+styleMode);

        calTempCal.set(Calendar.YEAR, targetYear);
        calTempCal.set(Calendar.MONTH, targetMonth);
        calTempCal.set(Calendar.DAY_OF_MONTH, 1);
        calTempCal.set(Calendar.HOUR_OF_DAY, 0); // Work from 1 am to avoid DST change issues
        calTempCal.set(Calendar.MINUTE, 0);
        calTempCal.set(Calendar.SECOND, 0);
        calTempCal.set(Calendar.MILLISECOND, 0);

        int prevYear = targetYear - 1;
        int nextYear = targetYear + 1;

        String prevMonth = ""; //this is for day view
        String nextMonth = "";
        int preMonth = 0;
        int nexMonth = 0;

        // Set up start date calendar here -- less work to duplicate later
        Calendar calStartCal = (Calendar) calTempCal.clone();
        Calendar activeMonthCal = (Calendar) calTempCal.clone();
        // It is pretty much imperative we collect this value now before the calendar object changes from the current month
        int daysInMonth = calStartCal.getActualMaximum(Calendar.DAY_OF_MONTH);
        System.out.println(daysInMonth+"  days in month");

        // Work out the bounds for the current display
        calStartCal.set(Calendar.YEAR, targetYear);
        calStartCal.set(Calendar.MONTH, targetMonth);
        boolean isInCurrentMonth = ((calToday.get(Calendar.YEAR) == targetYear) && (calToday.get(Calendar.MONTH) == targetMonth));
        int todaysDay = calToday.get(Calendar.DAY_OF_MONTH);
        System.out.println("isInCurrentMonth::"+isInCurrentMonth);

        //Date monthStartDate = new Date(calStartCal.getTime().getTime());
        Calendar endCal = null;
        Calendar calEventsData = null;
        Calendar rightCal = null;
        int daysToDisplay = 0;
        //this is for Monthly and Block view8
        if ("M".equals(displayMode) && "B".equals(styleMode)){

            // The start point is the first day of the week before the first day of the month
            int firstDay_Index = calStartCal.get(Calendar.DAY_OF_WEEK) - Calendar.MONDAY;
            //Month 1st starts with Sunday, then firstDay_Index will be -1
            if (firstDay_Index == -1){
                firstDay_Index = 6;  //moving to Monday in previous month
            }
            System.out.println("firstDay_Index::"+firstDay_Index);
            calStartCal.add(Calendar.DAY_OF_MONTH, -firstDay_Index);
            // Offset any potential daylight savings differences
            calStartCal.set(Calendar.HOUR_OF_DAY, 0);
            calStartCal.set(Calendar.MINUTE, 0);
            calStartCal.set(Calendar.SECOND, 0);
           
            daysToDisplay = firstDay_Index + daysInMonth + 6;
            
            daysToDisplay -= daysToDisplay % 7;
            rightCal =(Calendar)calStartCal.clone();
            // The number of days should be rounded up to the nearest multiple of 7.
           
            System.out.println("daysToDisplay::"+daysToDisplay);
            //another calendar required to render events data
            calEventsData = (Calendar)calStartCal.clone();
            endCal = (Calendar) calStartCal.clone();
            endCal.add(Calendar.DAY_OF_MONTH, (daysToDisplay-1)); //-1 because endCal must by end of the current calendar month
            endCal.set(Calendar.HOUR_OF_DAY, 23);
            endCal.set(Calendar.MINUTE, 59);
            endCal.set(Calendar.SECOND, 59);
            endCal.set(Calendar.MILLISECOND, 0);
        }else if ("M".equals(displayMode)&& ("L".equals(styleMode) || "C".equals(styleMode))){
            //this is for Montly and List/Condensed style modes.
            calEventsData = (Calendar)calStartCal.clone();
            rightCal =(Calendar)calStartCal.clone();

            endCal = (Calendar) calStartCal.clone();
            endCal.add(Calendar.DAY_OF_MONTH, (daysInMonth-1)); //-1 because endCal must be end of the current calendar month
            endCal.set(Calendar.HOUR_OF_DAY, 23);
            endCal.set(Calendar.MINUTE, 59);
            endCal.set(Calendar.SECOND, 59);
            endCal.set(Calendar.MILLISECOND, 0);
        }else if ("D".equals(displayMode)){      //for day view, both startCal and endCal have same value
            sdf = new SimpleDateFormat("MMMM");  
            daysToDisplay = 1;

            if (targetDay == 0 && isInCurrentMonth){
                targetDay = todaysDay;
            }
            if (targetDay > 0){
                calStartCal.set(Calendar.DAY_OF_MONTH, targetDay);
                calStartCal.set(Calendar.HOUR_OF_DAY, 0);
                calStartCal.set(Calendar.MINUTE, 0);
                calStartCal.set(Calendar.SECOND, 0);
            }else{
                targetDay = calStartCal.get(Calendar.DAY_OF_MONTH);
            }
            rightCal =(Calendar)calStartCal.clone();
            calEventsData = (Calendar)calStartCal.clone();
            endCal = (Calendar) calStartCal.clone();
            calTempCal = (Calendar)calStartCal.clone(); //this is for showing date label like Tuesday, January 1, 2013
            
            endCal.set(Calendar.HOUR_OF_DAY, 23);
            endCal.set(Calendar.MINUTE, 59);
            endCal.set(Calendar.SECOND, 59);
            endCal.set(Calendar.MILLISECOND, 0);
            
            calEventsData.add(Calendar.MONTH, -1);   //back to previous month
            prevMonth = sdf.format(calEventsData.getTime());
            preMonth = calEventsData.get(Calendar.MONTH);
            prevYear = calEventsData.get(Calendar.YEAR);
            calEventsData.add(Calendar.MONTH, 2); //move to next month from current month
            nextMonth = sdf.format(calEventsData.getTime());
            nexMonth = calEventsData.get(Calendar.MONTH);
            nextYear = calEventsData.get(Calendar.YEAR);

            calEventsData = (Calendar)calStartCal.clone();

            sdf = new SimpleDateFormat("EEEE, MMMM d, yyyy");
        }else if ("W".equals(displayMode)){ //for weekly mode
            daysInMonth = 7;   //this is for List/Condensed mode
            daysToDisplay = 7;  //this is for Block view
            if (targetDay == 0 && isInCurrentMonth){
                targetDay = todaysDay;
            }else if (targetDay == 0){
                targetDay = calStartCal.get(Calendar.DAY_OF_MONTH);
            }
             if (targetDay > 0){
                calStartCal.set(Calendar.DAY_OF_MONTH, targetDay);
                calStartCal.set(Calendar.HOUR_OF_DAY, 0);
                calStartCal.set(Calendar.MINUTE, 0);
                calStartCal.set(Calendar.SECOND, 0);
                int firstDay_Index = calStartCal.get(Calendar.DAY_OF_WEEK) - Calendar.MONDAY;
                if (firstDay_Index > 0){ //if it's zero then  start of week is Monday
                   calStartCal.add(Calendar.DAY_OF_MONTH, -firstDay_Index); //going to neareast Monday week
                }else if (firstDay_Index == -1){ //week started with Sunday
                   calStartCal.add(Calendar.DAY_OF_MONTH, 1); //going forward to Monday
                }
                  // Offset any potential daylight savings differences
                 calStartCal.set(Calendar.HOUR_OF_DAY, 0);
                 calStartCal.set(Calendar.MINUTE, 0);
                 calStartCal.set(Calendar.SECOND, 0);
            }
            calEventsData = (Calendar)calStartCal.clone();
            rightCal =(Calendar)calStartCal.clone();
            endCal = (Calendar) calStartCal.clone();
            calTempCal = (Calendar)calStartCal.clone(); 

            endCal.add(Calendar.DAY_OF_MONTH, 6);
            endCal.set(Calendar.HOUR_OF_DAY, 23);
            endCal.set(Calendar.MINUTE, 59);
            endCal.set(Calendar.SECOND, 59);
            endCal.set(Calendar.MILLISECOND, 0);


        }
        System.out.println("startCal::"+calStartCal.getTime());
        System.out.println("endCal::"+endCal.getTime());


        int day;
        int year;
        String cssClass;
        int month;
        String key;
        List<ManagedObject> list;
		List<ManagedObject> list1;
        String title;
        String color;
        int count;
        String startTime;
        String endTime;
        String time;
        Date startDate;
        Date endDate;
        SimpleDateFormat sdf1 = new SimpleDateFormat("EEE");
        String monthAndDay;
        String strDay;
        String siteName = rc.getCurrentSiteBean().getSystem().getName();
        Calendar resStartCal;
        resStartCal = (Calendar) calStartCal.clone();
        
        resStartCal.set(Calendar.DAY_OF_MONTH, -31);
            
        Map<String, List<ManagedObject>> eventsMap = CDAUtil.getEventsByCalendarMonth(resStartCal.getTime(),
                endCal.getTime(), siteName, styleMode, eventCategories, eventText, caseSensitive);
        System.out.println("Time took to process java methods::"+(System.currentTimeMillis()-sTime));
%>
<%
    List listfilter = CDAUtil.getEventTypesBeanList();
    if (listfilter != null){
        pageContext.setAttribute("results",listfilter);
    }
%>
<!--Right hand start PATRICK
	events returned count: <%=eventsMap.size()%>
	Request parameters:
	category:<%=eventCategories%>
	eventText:<%=eventText%>
	caseSensitive:<%=caseSensitive%>
	targetYear:<%=targetYear%>
	targetMonth:<%=targetMonth%>
	targetDay:<%=targetDay%>
	displayMode:<%=displayMode%>
	styleMode:<%=styleMode%>
	timePlanWidth:<%=timePlanWidth%>
	timePlanStartHour:<%=timePlanStartHour%>
	timePlanBlockSize:<%=timePlanBlockSize%>
-->
<script type="text/javascript">
function refreshParent1(){
             
                 var findText = document.getElementById("CATvalue").value;
                 
                

                     document.ui_eventCalender.eventText.value = findText;
					 document.ui_eventCalender.action = '<%=linkUrl%>';
                     document.ui_eventCalender.submit();
                     
          
        }



    function clearFilters(){
        var obj1 = document.getElementById("eventCategories");
        var obj2 = document.getElementById("eventText");
        var obj3 = document.getElementById("caseSensitive");
        if (obj1 && obj2 && obj3){
            obj1.value = "";
            obj2.value = "";
            obj3.value = "";
            submitPage();
        }
    }
    function dayChange(day,month,year){
        var obj = document.getElementById("targetDay");
        if (obj){
            //alert(obj.value);
            obj.value = day;
            obj = document.getElementById("targetMonth");
            obj.value = month;
            obj = document.getElementById("targetYear");
            obj.value = year;
            document.ui_eventCalender.action = '<%=linkUrl%>?displayMode=D';
            document.ui_eventCalender.submit();
        }else{
            alert('object doesnt exists');
        }
    }
    function openFilter(){
        window.open("<%=TemplatingConstants.FILTER_JSP%>","Filter","resizable=yes,scrollbars=yes,width=390,height=350");
    }
    function submitPage(){
        
        document.ui_eventCalender.action = '<%=linkUrl%>';
        document.ui_eventCalender.submit();
        
    }
    function onDropDownChange(){
        submitPage();    
    }
    function yearChange(year){
        //alert('inside yearchange::'+year);
        var obj = document.getElementById("targetYear");
        if (obj){
            //alert(obj.value);
            obj.value = year;
            document.ui_eventCalender.action = '<%=linkUrl%>';
            document.ui_eventCalender.submit();
        }else{
            alert('object doesnt exists');
        }
    }
    function monthChange(month,year){
       // alert('inside monthChange::'+month);
        var obj = document.getElementById("targetMonth");
        if (obj){
		
            //alert(obj.value);
            obj.value = month;
            obj = document.getElementById("targetYear");
            obj.value = year;
		  document.ui_eventCalender.action ='<%=linkUrl%>';
		//alert(obj.value);
            document.ui_eventCalender.submit();
        }else{
            alert('object doesnt exists');
        }
    }
 
    function selectedMonth(){
	var obj = document.getElementById("selMonth").value;
	var obj2 = document.getElementById("selYear").value;
	monthChange(obj,obj2);
    }
    function selectedYear(){
	var obj = document.getElementById("selYear").value;
       
	yearChange(obj);
    }

     function selectedWeek(){
	var obj = document.getElementById("selWeek").value;
	 var obj_array = obj.split(',');
	 
	weekChange(obj_array[0],obj_array[1],obj_array[2]);

    }
    function yearMonthChange(month, year){
        var obj1 = document.getElementById("targetMonth");
        var obj2 = document.getElementById("targetYear");
        var obj3 = document.getElementById("targetDay");
        if (obj1 && obj2 && obj3){
            obj1.value = month;
            obj2.value = year;
            obj3.value = 0; //bcoz feb have only 28 days
            document.ui_eventCalender.action = '<%=linkUrl%>';
            document.ui_eventCalender.submit();
        }
    }
    function weekChange(month, year, day){
        var obj1 = document.getElementById("targetMonth");
        var obj2 = document.getElementById("targetYear");
        var obj3 = document.getElementById("targetDay");
        if (obj1 && obj2 && obj3){
            obj1.value = month;
            obj2.value = year;
            obj3.value = day; //bcoz feb have only 28 days
            document.ui_eventCalender.action = '<%=linkUrl%>?displayMode=W';
            document.ui_eventCalender.submit();
        }
    }
</script>



<div class="row bottom-devider">
                    <div class="calendar_display_setting">
					<div >
<% if("M".equals(displayMode)){out.println("<a class=\"active\"><b> Month </b></a>"); } else{out.println(" <a href=\""+linkUrl+"?displayMode=M\" onClick=\"onDropDownChange()\">Month</a>" );} %>
</div>
<div><%if("W".equals(displayMode)){out.println("<a class=\"active\"><b> Week </b></a> ");} else{out.println("<a href=\""+linkUrl+"?displayMode=W\" onClick=\"onDropDownChange()\">Week</a> " );}%>
</div>
<div><% if("D".equals(displayMode)){out.println("<a class=\"active\"><b> Day </b></a> ");}else{out.println("<a href=\""+linkUrl+"?displayMode=D\" onClick=\"onDropDownChange()\">Day </a> " );}%>
</div>
 
</div>

</div>
 <div>
                            <ul class="nav">
                                <li class="dropdown hidden-xs hidden-sm active">
                                    <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">All events <span class="caret"></span></a>
                                    <ul class="dropdown-menu" role="menu">
                                        <li><a href="#">Conferences</a></li>
                                        <li><a href="#">Inaugural lectures</a></li>
                                        <li><a href="#">Annual events</a></li>
                                        <li><a href="#">Symposiums</a></li>
                                        <li><a href="#">Workshops</a></li>
                                        <li><a href="#">Summer schools</a></li>
                                        <li><a href="#">Launch events</a></li>
                                    </ul>
                                </li>
                            </ul>
                        </div>
</div>

</div>


<%	
			Calendar tempCal1 = (Calendar)activeMonthCal.clone();
			Calendar tempDayCal = (Calendar)activeMonthCal.clone();
			tempDayCal.add(Calendar.MONTH,-1);
			int lastmon = tempDayCal.get(Calendar.MONTH);
			int lastmonYear = tempDayCal.get(Calendar.YEAR);
			tempDayCal = (Calendar)activeMonthCal.clone();
			tempDayCal.add(Calendar.MONTH,1);
			int nextmon= tempDayCal.get(Calendar.MONTH);
			int nextmonYear= tempDayCal.get(Calendar.YEAR);
			
			String lbutton = "";
			String rbutton= "";
            int eday = tempCal1.get(Calendar.DAY_OF_MONTH);
            int emonth = tempCal1.get(Calendar.MONTH);
            int eyear = tempCal1.get(Calendar.YEAR);
            tempDayCal = (Calendar)calStartCal.clone();
        	tempDayCal.add(Calendar.DATE,-1);        
            int dayless = tempDayCal.get(Calendar.DAY_OF_MONTH);
            int dayLessMonth = tempDayCal.get(Calendar.MONTH);
            int dayLessYear = tempDayCal.get(Calendar.YEAR);
            
            tempDayCal = (Calendar)calStartCal.clone();
        	tempDayCal.add(Calendar.DATE,1);        
            int daymore =  tempDayCal.get(Calendar.DAY_OF_MONTH);           
            int daymoreMonth = tempDayCal.get(Calendar.MONTH);
            int daymoreYear = tempDayCal.get(Calendar.YEAR);

			if("M".equals(displayMode)){
			   lbutton = "monthChange("+lastmon+","+lastmonYear+")";
			   rbutton = "monthChange("+nextmon+","+nextmonYear+")";
			}else if("W".equals(displayMode)){
			   Calendar tempCalless = (Calendar)calStartCal.clone();
			   	tempCalless.add(Calendar.WEEK_OF_MONTH, -1);
				int wmonth = tempCalless.get(Calendar.MONTH);
                            int wday = tempCalless.get(Calendar.DAY_OF_MONTH);
                            int wyear = tempCalless.get(Calendar.YEAR);
			   lbutton = "weekChange("+wmonth+","+wyear+","+wday+")";
				Calendar tempCalmore = (Calendar)calStartCal.clone();

				tempCalmore.add(Calendar.WEEK_OF_MONTH, 1);
				wmonth = tempCalmore.get(Calendar.MONTH);
                            wday = tempCalmore.get(Calendar.DAY_OF_MONTH);
                            wyear = tempCalmore.get(Calendar.YEAR);

			   rbutton = "weekChange("+wmonth+","+wyear+","+wday+")";

			} else{
			   lbutton = "dayChange("+dayless+","+dayLessMonth+","+dayLessYear+")";
			   rbutton = "dayChange("+daymore+","+daymoreMonth+","+daymoreYear+")";
			}
	%>
<!--Calendar Start Patrick-->

    <% 
				String Heading = "";
				
				if("M".equals(displayMode)){
					Heading = "Month of " +sdf.format(calTempCal.getTime()) ; } 
					else if("W".equals(displayMode)){
						Heading = "Week of " + calStartCal.get(Calendar.DAY_OF_MONTH) + " " + sdf.format(calTempCal.getTime()) ; } 
							else if("D".equals(displayMode)){
								Heading = sdf.format(calTempCal.getTime()) ; }
								
								
			%>


<div class="row">
                	<div class="calendar_heading">
               	<h1><% out.println(Heading); %></h1>
</div>



                    </div>
<%     
	
		Calendar middleCal = (Calendar) calStartCal.clone();
 		for (int i=1; i <= daysToDisplay; i++){
        		day = middleCal.get(Calendar.DAY_OF_MONTH);
        		month = middleCal.get(Calendar.MONTH);
        		sdf = new SimpleDateFormat("dd MMMM yyyy");
        		sDate = sdf.format(middleCal.getTime());
        		middleCal.add(Calendar.DAY_OF_MONTH, 1);
        		

            		month += 1; //calendar gives 0 value for January month, so adding one
            		key = day+"-"+month;     //this is hash map key. It gives list of events on that particualr day and month
            		//out.print("m key:"+key);
            		if (eventsMap.containsKey(key)){
                		list = eventsMap.get(key);
				key = "";
            		}else{
                		list = null;
            		}
            		if (list == null){
    			%>
    				<!--this is empty cell... -->    
    			<%
    			}else{

        			CDAUtil.sortEventsByStartDateAndEndDate(list); //sorting to get more than one day spawned records first
        			count = 1;
        			
        			//out.print("m list size:"+list.size()+"->m list:"+list);
        			for (ManagedObject mo:list){
            				title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
            				startTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_START_TIME);
            				endTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_END_TIME);
            				startDate = (Date)mo.getAttributeValue(TemplatingConstants.EVENT_START_DATE);
            				sdf = new SimpleDateFormat("dd MMM yyyy");
            				//sDate = sdf.format(startDate);
            				//sDate = sdf.format(middleCal.getTime());
            				//sDate = new String((""+startDate).substring(0,10));
            				endDate = (Date)mo.getAttributeValue(TemplatingConstants.EVENT_END_DATE);            				
            				
            				time = null;
            				
            				boolean isRecurring = false;
            				boolean isDurationDisplayed = false;
            				boolean isDuration = false;
            				boolean isFullDay = false;
            				long diffDays = (endDate.getTime() - startDate.getTime())/(24 * 60 * 60 * 1000);   
            				String durationStr = "";
            				
            				if (!TemplatingConstants.FULL_TIME.equals(startTime)){
                				//time configured
                				startTime = new String(startTime.substring(0,startTime.lastIndexOf(":")));
                				endTime = new String(endTime.substring(0,endTime.lastIndexOf(":")));
                				if (!TemplatingConstants.HALF_TIME.equals(endTime) && !"".equals(endTime.trim()) && !":00".equals(endTime.trim()) ){
                					if ( !"".equals(startTime.trim()) && !":00".equals(startTime.trim())){
                    					time = startTime+" - "+endTime;
                					}else{
                						//time = NO_START_TIME+" - "+endTime;
										time = "";
                					}
                				}else{
                					if ( !"".equals(startTime.trim()) && !":00".equals(startTime.trim())){
                    					//time = startTime+" - "+NO_END_TIME;
										time = startTime;
                					}else{
                						//time = NO_START_TIME+" - "+NO_END_TIME;
										time = "";
                					}
                				}            				
                				if(diffDays == 0 && recurEventsMap.containsKey(title) ){                					            					
                					//time = time + RECURRING;  
                					isRecurring = true;
                				}else if(diffDays > 0 ){
            						//time = time +" ("+ diffDays + DURATION +") - ";  
            						durationStr = " ("+ diffDays + DURATION +") - "; 
            						isDuration = true;
            						
            						if(displayedDurationEvents.containsKey(title) ){
            							isDurationDisplayed = true;
            						}else{
            							displayedDurationEvents.put(title,1);
            						}
            						
            					} 
                				if ( "".equals(startTime.trim()) && "".equals(endTime.trim())){
                					if(time.trim().equals("-")){
                						time = "";
                					}
                					isFullDay = true;
                					//time = time + FULL_DAY;
                				}
            				}
            				
            			if(!isDurationDisplayed ){ 
            				if(!previousDate.equalsIgnoreCase(sDate)){	
                					
                				if(i == 1){ %>
        	        				<div>
										<h4><%=sDate%></h4>
        	        			<%}	
                				if(i != 1){ %>
        	        				<div>
										<h4><%=sDate%></h4>
        	        			<%}} %>
							<div>
	                        		<%if (time != null) {%>						
	                        			<div>
										<%=time%><%if(isRecurring){%><%=RECURRING%><%} %>
	                        			<%if(isDuration){%><%=durationStr%><%} %>
	                        			<%if(isFullDay){%><%=FULL_DAY%><%} %>
                                        </div>
	                        		<%}%>
	                        			<div>
										<%=CDAUtil.buildLink(mo, rc, "eventlink", "calendarevent")%>
                                        </div>
							</div>
	
	        				<% 
            				}else if(isDurationDisplayed ){ 
                				if(!previousDate.equalsIgnoreCase(sDate)){	
                    					
                    				if(i == 1){ %>
            	        				<div>
    										<h4><%=sDate%></h4>
            	        			<%}	
                    				if(i != 1){ %>
            	        				<div>
    										<h4><%=sDate%></h4>
            	        			<%}} %>
    							<div>
    	                        		<%if (time != null) {%>						
    	                        			<div>
    										<%=time%><%if(isRecurring){%><%=RECURRING%><%} %>
    	                        			<%if(isDuration){%><%=durationStr%><%} %>
    	                        			<%if(isFullDay){%><%=FULL_DAY%><%} %>
                                            </div>
    	                        		<%}%>
    	                        			<div>
    										<%=CDAUtil.buildLink(mo, rc, "eventlink", "calendarevent")%>
                                            </div>
    							</div>
    	
    	        				<% 
                				}
            			
            		count += 1;
    				previousDate = sDate;
    				
    				if(recurEventsMap.containsKey(title)){
    					Integer temp = recurEventsMap.get(title);
    					temp = new Integer(temp.intValue() +1 );
    					recurEventsMap.put(title,temp);
    					
    				}else{
    					recurEventsMap.put(title,new Integer(1));
    				}
        			} %>
					</div>
        		<% }

        		calEventsData.add(Calendar.DAY_OF_MONTH, 1);
        			
    		} %>
  
	
	</div>
                        
<div class="row">
                	<div class="calendar_navigation">
<% if("M".equals(displayMode)){ %>

                    	<div class="btn btn-primary" onclick="<%=lbutton%>">Previous</div>
                        <div class="btn btn-primary pull-right" onclick="<%=rbutton%>">Next</div>
                    
    	
    <% } %>
	
<% if("W".equals(displayMode)){ %>
	
                    	<div class="btn btn-primary" onclick="<%=lbutton%>">Previous</div>
                        <div class="btn btn-primary pull-right" onclick="<%=rbutton%>">Next</div>
                    
    	
                    
                   
    <% } %>
<% if("D".equals(displayMode)){ %>
	
                    		  	<div class="btn btn-primary" onclick="<%=lbutton%>">Previous</div>
                        <div class="btn btn-primary pull-right" onclick="<%=rbutton%>">Next</div>
                    
    	
                    
                  
    <% } %>
	
  </div>
                </div>	
    </div>
    </div>
<!--RIGHT-->

<div class="col-lg-3 col-md-3 col-sm-3 hidden-xs side">
				<form>
					<input type="text" class="form-control" placeholder="Search calendar...">
				</form>
                <div class="calendar_month_display bottom-devider">
                	<div class="clearfix">
					<form method="get" name="ui_eventCalender" action="<%=linkUrl%>">

                <div class="btn btn-primary pull-left"  onclick="<%=lbutton%>">&lt;
				</div>

                <div><% if("M".equals(displayMode)){out.println(""); } else if("W".equals(displayMode)){out.println("Week of ");} else if("D".equals(styleMode)){out.println("");}%><%=sdf.format(calTempCal.getTime())%>
				</div>

                <div class="btn btn-primary pull-right" onclick="<%=rbutton%>">&gt;</a>
				</div>
         
	<script type="text/javascript" src="/sites/scripts/search.js">
		
	</script>
	<script type="text/javascript">
		function searchByEnter(e) {
			if (e.keyCode == 13) {
				search();
			}
		}

		
		
		
		function search() {
			startSearch(document.getElementById('searchText_5b2f67b2eecec310VgnVCM1000002be3910aRCRD').value, '', '/sites/eConnect/News-&-Communications/Events/Events-Search-Results');
		}
              function validateSearch(){
			if(document.getElementById('searchText_5b2f67b2eecec310VgnVCM1000002be3910aRCRD').value==null||document.getElementById('searchText_5b2f67b2eecec310VgnVCM1000002be3910aRCRD').value==" "){}else{
				search();
			}
		}
	</script>

	
	 
</div>


<% if (("M".equals(displayMode) || "W".equals(displayMode)) && "B".equals(styleMode)){ %>
<center>
 <table class="calendar_table">
<tbody>
<tr>
    <!--this is for calendar header like Monday, Tuesday etc... -->
    <%
        Calendar dayNameCal = (Calendar) calStartCal.clone();

        sdf = new SimpleDateFormat("EEEE");
        for (int i=1; i <= 7;i++){
		String daynam = ""+(sdf.format(dayNameCal.getTime())).toString().substring(0,1);
    %>
    <th><%=daynam%></th>

    <%
            dayNameCal.add(Calendar.DAY_OF_MONTH, 1);
        }
    %>
</tr>

<%
    //sdf = new SimpleDateFormat("d");
    String newday="";
    //int diff;
    for (int i=1; i <= daysToDisplay; i++){
        day = rightCal.get(Calendar.DAY_OF_MONTH);//Integer.parseInt(sdf.format(calStartCal.getTime()));
        month = rightCal.get(Calendar.MONTH);
        int monthInx = month + 1;
		key = day+"-"+monthInx;     //this is hash map key. It gives list of events on that particualr day and month
		
		boolean isempty = false;
        if (eventsMap.containsKey(key)){
        	list = eventsMap.get(key);
        	if(list != null && list.size()> 0){
        		isempty = false;
        	}else {
        		isempty = true;
        	}
		} else {
			isempty = true;
		}
        
        key = "";
        if (i == 1){
%>
<!--this is for calendar days like 1, 2, 3 etc.. -->
<tr>
    <%}
	if (isempty) {
	%>
    <td class="<%=(isInCurrentMonth && (day == todaysDay && targetMonth == month))?"Common_RightPanel_todaysdate":"Common_RightPanel_dayofmonth"%>" >
        <span class="<%=(isInCurrentMonth && (day == todaysDay && targetMonth == month))?"Common_RightPanel_todaysdate_link":"Common_RightPanel_dayofmonth_link"%>"><a href="#" onclick="dayChange(<%=day%>,<%=rightCal.get(Calendar.MONTH) %>,<%=rightCal.get(Calendar.YEAR) %>)" >
                                                           <%=day%>
                                                       </a></span>
		<% newday=""+day;%>
    </td>
    <%
	} else { %>
    <td class="<%=(isInCurrentMonth && (day == todaysDay && targetMonth == month))?"Common_RightPanel_todaysdate_hasevents":"Common_RightPanel_dayofmonth_hasevents"%>"  colspan="2">
        <span class="<%=(isInCurrentMonth && (day == todaysDay && targetMonth == month))?"Common_RightPanel_todaysdate_link_hasevents":"Common_RightPanel_dayofmonth_link_hasevents"%>"><a href="#" onclick="dayChange(<%=day%>,<%=rightCal.get(Calendar.MONTH) %>,<%=rightCal.get(Calendar.YEAR) %>)" >
                                                           <%=day%>
                                                       </a></span>
		<% newday=""+day;%>
    </td>
    
    
    <% }
    rightCal.add(Calendar.DAY_OF_MONTH, 1);

        if (i % 7 == 0){ %>
</tr>
<!--this is for events data... -->
<tr>
    
</tr>
<% if (i < daysToDisplay) { %>
<!--this is for rendering next days rows -->
<tr>
    <%}
     }
   } %>


</tbody>
</table>
</center>
<%}else if ((("M".equals(displayMode) || "D".equals(displayMode) || "W".equals(displayMode) )) && (("L".equals(styleMode)) || "C".equals(styleMode))){
    if ("D".equals(displayMode)){
        daysInMonth = 1; //for days view, show only one day event data.
    }
%>
<center>
 <table class="calendar_table">
<tbody>
<%
                sdf = new SimpleDateFormat("MMM d");
                ManagedObject mo;
                for (int i=1; i<= daysInMonth ;i++){
                    monthAndDay = sdf.format(calEventsData.getTime());
                    strDay = sdf1.format(calEventsData.getTime());

                    month = calEventsData.get(Calendar.MONTH);
                    day =  calEventsData.get(Calendar.DAY_OF_MONTH);

                    month += 1; //calendar gives 0 value for January month, so adding one
                    key = day+"-"+month;     //this is hash map key. It gives list of events on that particualr day and month

                    if (eventsMap.containsKey(key)){
                        list = eventsMap.get(key);
                        CDAUtil.sortEventsByStartDateAndEndDate(list);
                    }else{
                        list = null;
                    }

                    count  = (list == null)?0:list.size();
                    //in condensed mode, if no records exists on particular day, then don't need to render row for that day.
                    if ("C".equals(styleMode) && count == 0){
                        if ("M".equals(displayMode) || "W".equals(displayMode)){
                            calEventsData.add(Calendar.DAY_OF_MONTH, 1); //progressing for next day
                        }
                        continue;
                    }
            %>

<tr>
<td  class="<%=(isInCurrentMonth && (day == todaysDay))?"Common_MainContentArea_todaysdate":"Common_MainContentArea_listdefaultmonthbg"%>">
<span class="<%=(isInCurrentMonth && (day == todaysDay))?"Common_MainContentArea_todaysdate_link":"Common_MainContentArea_listdatelink"%>"><%=monthAndDay%></span>
</td>
<td class="Common_RightPanel_listshortdaytext"><%=strDay%></td>
<% if (count > 0) {
                    mo = list.get(0); //for rendering first event
                    //title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
                    startTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_START_TIME);
                    endTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_END_TIME);
                    time = null;
                    if (!TemplatingConstants.FULL_TIME.equals(startTime)){
                        //time configured
                        startTime = new String(startTime.substring(0,startTime.lastIndexOf(":")));
                        endTime = new String(endTime.substring(0,endTime.lastIndexOf(":")));
                        if (!TemplatingConstants.HALF_TIME.equals(endTime)){
                            time = startTime+" -"+endTime;
                        }else{
                            time = startTime;
                        }
                    }

%>
<td>
<% if (time != null){ %>
<span><%=time%></span>
<%}%>    
<%=CDAUtil.buildLink(mo,rc,"listeventlink","listcalendarevent")%>
</td>
<td>&nbsp;

</td>
    <%}else{%>
      <td >&nbsp;</td>
        <td>&nbsp;
        
      </td>
    <%}%>
</tr>
<%
                    for (int j=1;j<count;j++){ //this is for iterating remaining elements in list and display it
                        mo = list.get(j);
                        //title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
                        startTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_START_TIME);
                        endTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_END_TIME);
                        time = null;
                        if (!TemplatingConstants.FULL_TIME.equals(startTime)){
                            //time configured
                            startTime = new String(startTime.substring(0,startTime.lastIndexOf(":")));
                            endTime = new String(endTime.substring(0,endTime.lastIndexOf(":")));
                            if (!TemplatingConstants.HALF_TIME.equals(endTime)){
                                time = startTime+" -"+endTime;
                            }else{
                                time = startTime;
                            }
                        }
                        if (j % 2 == 0){
                            color = "#BFC8D9";
                        }else{
                            color = "#B8CCBC";
                        }
                        %>
<tr><td>
    <% if (time != null){ %>
    <span><%=time%></span>
    <%}%>    
    <%=CDAUtil.buildLink(mo, rc, "listeventlink", "listcalendarevent")%>
</td>
    <td>&nbsp;
        </td>
</tr>
       <% }
          if ("M".equals(displayMode) || "W".equals(displayMode)){ //for month and weekly view, day must be progressed for list and condensed modes
            calEventsData.add(Calendar.DAY_OF_MONTH, 1); //progressing for next day
          }
       }
       %></tbody></table></center>
<%}else if ("D".equals(displayMode) && !("T".equals(styleMode))){ %>
<center>
    <table>
        <tbody>
            <tr>
                <th><%=new SimpleDateFormat("EEEE").format(calStartCal.getTime())%></th>
            </tr>
            <tr>
                <td class="<%=(isInCurrentMonth && targetDay == todaysDay)?"Common_RightPanel_todaysdate":"Common_RightPanel_dayofmonth"%>">
                    <span class="<%=(isInCurrentMonth && targetDay == todaysDay)?"Common_RightPanel_todaysdate_link":"Common_RightPanel_dayofmonth_link"%>"><%=calStartCal.get(Calendar.DAY_OF_MONTH)%></span>
                </td>
                <td><%=new SimpleDateFormat("MMM").format(calStartCal.getTime())%></td>
            </tr>
            <%
                day = calStartCal.get(Calendar.DAY_OF_MONTH);
                month = calStartCal.get(Calendar.MONTH);

                month+=1; //calendar gives 0 value for January month, so adding one

                key = day+"-"+month;

                if (eventsMap.containsKey(key)){
                    list = eventsMap.get(key);
                    CDAUtil.sortEventsByStartDateAndEndDate(list);
                }else{
                    list = null;
                }
                ManagedObject mo;
                count = (list == null)?0:list.size();
                if (count == 0){ %>
                 <tr>
                     <td>&nbsp;</td>
                  </tr>
               <%}else{
               %>
                    <tr>
                        <td>
                <%
                   for (int j= 0; j<count; j++){ //this is for iterating  elements in list and display it
                        mo = list.get(j);
                        //title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
                        startTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_START_TIME);
                        endTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_END_TIME);
                        time = null;
                        if (!TemplatingConstants.FULL_TIME.equals(startTime)){
                            //time configured
                            startTime = new String(startTime.substring(0,startTime.lastIndexOf(":")));
                            endTime = new String(endTime.substring(0,endTime.lastIndexOf(":")));
                            if (!TemplatingConstants.HALF_TIME.equals(endTime)){
                                time = startTime+" -"+endTime;
                            }else{
                                time = startTime;
                            }
                        }
                        if (j % 2 == 0){
                            color = "#BFC8D9";
                        }else if (j % 3 == 0){
                            color = "#D5C8B5";
                        }else {
                            color = "#B8CCBC";
                        }
                %>

<table>
    <tbody>
        <tr>
            <td>
                <% if (time != null){ %>
                <span><%=time%></span>
                <%}%>
                <%=CDAUtil.buildLink(mo, rc, "eventlink", "calendarevent")%>
            </td>
        </tr>
    </tbody>
</table>


              <% } %>
    </td>
</tr>                    
            <%  }
            %>
        </tbody>
    </table>
</center>
<%}else if (("W".equals(displayMode) || "D".equals(displayMode)) && "T".equals(styleMode)){
     if ("D".equals(displayMode)){
        daysInMonth = 1; //for days view, show only one day event data.
    }
%>
<center>
    <table>
        <tbody>
            <tr>
                <td>&nbsp;Display:&nbsp;&nbsp;
                    <select name="timePlanWidth" onchange="onDropDownChange()">                        
                        <option value="4" <%=(4 == timePlanWidth)?"selected='selected'":""%>>4 Hours</option>
                        <option value="8" <%=(8 == timePlanWidth)?"selected='selected'":""%>>8 Hours</option>
                        <option value="10" <%=(10 == timePlanWidth)?"selected='selected'":""%>>10 Hours</option>
                        <option value="12" <%=(12 == timePlanWidth)?"selected='selected'":""%>>12 Hours</option>
                        <option value="24" <%=(24 == timePlanWidth)?"selected='selected'":""%>>24 Hours</option>
                    </select>
                    &nbsp;&nbsp;Start Hour:&nbsp;&nbsp;
                    <select name="timePlanStartHour" onchange="onDropDownChange()"e>
                        <%for (int i=0; i<=23; i++){ %>
                            <option value="<%=i%>" <%=(i == timePlanStartHour)?"selected='selected'":""%>><%=i%>:00</option>
                        <%}%>
                     </select>
                    &nbsp;&nbsp;Block size:&nbsp;&nbsp;
                    <select>
                        <option value="1" <%=1 == timePlanBlockSize?"selected='selected'":""%> >1 hour</option>
                      
                    </select>
                </td>
                <td>
                    &nbsp;&nbsp;
                </td>
            </tr>
        </tbody>
    </table>
    <p>&nbsp;</p>
    <center>
        <table class="calenders">
            <tbody>
                <tr>
                    <td>
                        <span>?</span>
                    </td>
                    <%
                        sdf = new SimpleDateFormat("EEE dd");
                        Map<String, Integer> maxColSpanMap = new HashMap<String, Integer>();
                        for (int i=1; i<=daysInMonth; i++){
                            day = calEventsData.get(Calendar.DAY_OF_MONTH);
                            month = calEventsData.get(Calendar.MONTH);
                            month += 1;//adding one
                            key = day+"-"+month;
                            if (eventsMap.containsKey(key)){
                                list = eventsMap.get(key);
                                count = CDAUtil.getMaxColSpanValue(list, timePlanWidth, timePlanStartHour, timePlanBlockSize, timePlanEndHour);
                                maxColSpanMap.put(key, count);
                            }else{
                                count = 0;
                            }
                            strDay = sdf.format(calEventsData.getTime());
                            %>
                    <td width="<%="D".equals(displayMode)?"":"13%"%>" colspan="<%=count%>" style="TEXT-ALIGN: center" class="<%=(isInCurrentMonth && day == todaysDay)?"Common_RightPanel_todaysdate":"Common_RightPanel_dayofmonth"%>">
                            <span class="<%=(isInCurrentMonth && day == todaysDay)?"Common_RightPanel_todaysdate_link":"Common_RightPanel_dayofmonth_link"%>"><%=strDay%></span>
                    </td>
                       <%
                          calEventsData.add(Calendar.DAY_OF_MONTH, 1);  
                        }
                        calEventsData = null;
                        calEventsData = (Calendar)calStartCal.clone();

                    %>
                </tr>
                <tr>
                    <td>&nbsp;</td>
                    <%
                        Map<String, List<ManagedObject>> timePlanMap = CDAUtil.buildTimePlanMap(eventsMap, (Calendar)calEventsData.clone(),
                                daysInMonth, timePlanWidth, timePlanStartHour, timePlanBlockSize, timePlanEndHour);

                        for (int i=1; i<=daysInMonth; i++){
                            day = calEventsData.get(Calendar.DAY_OF_MONTH);
                            month = calEventsData.get(Calendar.MONTH);
                            month += 1;//adding one
                            key = day+"-"+month;
                            count = (maxColSpanMap.containsKey(key))?maxColSpanMap.get(key):0; //this is for ColSpan
                            key = day+"-"+month+"-"+0; //showing events start_date starts with 00:00:00
                            if (timePlanMap.containsKey(key)){
                               list = timePlanMap.get(key);
                               %>
                               <td >
                                   <span>
                                 <%
                                    for (ManagedObject mo:list){
                                        //title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
                                 %>

                                                    <table width="100%">
                                                        <tbody>
                                                            <tr>
                                                                <td >
                                                                    <%=CDAUtil.buildLink(mo, rc, "offeventlink", "calendarevent")%>
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                      </table>

                                   <% } %>
                                  </span>     
                               </td>
                            <% }else{ %>
                             <td>&nbsp;</td>
                           <% }

                             calEventsData.add(Calendar.DAY_OF_MONTH, 1);
                        } %>
                      </tr>
                      <%
                          //Don't need to render anything if startHour is zero
                         if (timePlanStartHour == 0){
                             calEventsData = null;
                             calEventsData = (Calendar)calStartCal.clone();
                      %>
                            <tr>
                                <td>0:00</td>

                        <%     for (int i=1; i<=daysInMonth;i++){
                                    day = calEventsData.get(Calendar.DAY_OF_MONTH);
                                    month = calEventsData.get(Calendar.MONTH);
                                    month += 1;//adding one
                                    key = day+"-"+month;
                                    count = (maxColSpanMap.containsKey(key))?maxColSpanMap.get(key):0; //this is for ColSpan
                                  %>
                                 <td>&nbsp;</td>
                            <%
                                    calEventsData.add(Calendar.DAY_OF_MONTH, 1);
                                } %>
                             </tr>   
                        <% }
                         timePlanStartHour = (timePlanStartHour == 0)?1:timePlanStartHour;
                         for (int i= timePlanStartHour ; i<=timePlanEndHour ;i++){
                            calEventsData = null;
                            calEventsData = (Calendar)calStartCal.clone();
                             %>
                            <tr>
                                <td><%=i%>:00</td>
                           <%
                            for (int j=1;j<=daysInMonth;j++){
                                day = calEventsData.get(Calendar.DAY_OF_MONTH);
                                month = calEventsData.get(Calendar.MONTH);
                                month += 1;//adding one
                                key = day+"-"+month+"-"+i; //showing events start_date starts with time
                                System.out.println("timeKey::"+key);
                                 if (timePlanMap.containsKey(key)){
                                    if (j % 2 == 0){
                                        color = "#BFC8D9";
                                    }else if (j % 3 == 0){
                                        color = "#D5C8B5";
                                    }else {
                                        color = "#B8CCBC";
                                    }
                                    list = timePlanMap.get(key);
                                    for (ManagedObject mo:list){
                                       startTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_START_TIME);
                                       endTime = (String)mo.getAttributeValue(TemplatingConstants.EVENT_END_TIME);
                                       count = CDAUtil.getMeTimeDifference(startTime, endTime);
                                       //title = (String)mo.getAttributeValue(TemplatingConstants.TITLE);
                                       startTime = new String(startTime.substring(0,startTime.lastIndexOf(":")));
                                       endTime = new String(endTime.substring(0,endTime.lastIndexOf(":")));
                                       if (!TemplatingConstants.HALF_TIME.equals(endTime)){
                                            time = startTime+" -"+endTime;
                                        }else{
                                            time = startTime;
                                        }
                                       %>
                                       <td>
                                           <span style="COLOR: 000000;" class="Common_RightPanel_fonttime"><%=time%>&nbsp;</span>                                            
                                            <%=CDAUtil.buildLink(mo, rc, "eventlink", "listcalendarevent")%>
                                       </td>
                                  <%  }
                                 }else{ %>
                                 <td>&nbsp;</td>
                                <%}
                                calEventsData.add(Calendar.DAY_OF_MONTH, 1);
                            } %>
                         </tr>  
                      <% } %>

            </tbody>
        </table>

    </center>
    <center></center>
</center>
<%}%>
<input type="hidden" name="displayMode" id="displayMode" value="<%=displayMode%>" />
<input type="hidden" name="targetYear" id="targetYear" value="<%=targetYear%>" />
<input type="hidden" name="targetMonth" id="targetMonth" value="<%=targetMonth%>" />
<input type="hidden" name="targetDay" id="targetDay" value="<%=targetDay%>" />
<input type="hidden" name="eventCategories" id="eventCategories" value="<%=eventCategories%>" />
<input type="hidden" name="eventText" id="eventText" value="<%=eventText%>" />
<input type="hidden" name="caseSensitive" id="caseSensitive" value="<%=caseSensitive%>" />





</form>
</div>



</div>

<div>
            <h3>Categories</h3>
            
                
                <templating:initComponent />
 <templating:contentItem result="content" />
 <c:if test="${not empty content}">  

               
                    <ul>
					<li><a href="<%=linkUrl%>?eventCategories=" target="_self">All Categories</a></li>
                                              
                           <c:if test="${not empty content.WEM_SYSTEM_UNISA_REFERENCE_DATA_OPTIONS}">
                                <templating:sort result="sortedRelatedItems" items="${content.WEM_SYSTEM_UNISA_REFERENCE_DATA_OPTIONS}" properties="ranking" order="ascending" />
                                <c:forEach var="entry" items="${sortedRelatedItems}">
                                     <li><a href="<%=linkUrl%>?eventCategories=${entry.value}" target="_self">${entry.name}</a></li>
                                </c:forEach>
                            </c:if>
                       
                            
                        
			        </ul>
           
            
        </div>




            	
    	
    
<%
        // Last second of the last day to display
        //String rcEndDate = String.valueOf(rcEndCal.getTimeInMillis() / 1000);
        System.out.println("Total Time took to render page::"+(System.currentTimeMillis()-sTime));
    }catch(Exception ex){
    ex.printStackTrace();
	out.println("exception:"+ex);
}
%>