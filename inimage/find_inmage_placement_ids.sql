select parent.name parent_name, child.name child_name, parent.status parent_status, parent.type parent_type, child.type child_type, parent.placement_kind, child.placement_kind
from kmn_layouts parent
inner join kmn_layouts child on child.parent_tag=parent.layoutid
where parent.type=4 and 
child.type=1 
-- and parent.placement_kind = 'inimage_parent';