$('#skill_category').on('change',function(){
  $.get('skill_category/'+this.value,function(data){

     for(var j = 0; j < length; j++)
     {

       $('#skill').contents().remove();
       var newOption = $('<option/>');
       newOption.attr('text', data[j].text);
       newOption.attr('value', data[j].value);
       $('#skill').append(newOption);
     }
  });
});