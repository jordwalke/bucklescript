(* Copyright (C) 2017 Authors of BuckleScript
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)


 let map_row_fields_into_ints ptyp_loc
    (row_fields : Parsetree.row_field list) 
  = 
  let _, acc
    = 
    (List.fold_left 
       (fun (i,acc) rtag -> 
          match rtag with 
          | Parsetree.Rtag (label, attrs, true,  [])
            -> 
            begin match Ast_attributes.iter_process_bs_int_as attrs with 
              | Some i -> 
                i + 1, 
                ((Ext_pervasives.hash_variant label , i):: acc ) 
              | None -> 
                i + 1 , 
                ((Ext_pervasives.hash_variant label , i):: acc )
            end
          | _ -> 
            Bs_syntaxerr.err ptyp_loc Invalid_bs_int_type
       ) (0, []) row_fields) in 
  List.rev acc

(** It also check in-consistency of cases like 
    {[ [`a  | `c of int ] ]}       
*)  
let map_row_fields_into_strings ptyp_loc 
    (row_fields : Parsetree.row_field list) = 
  let case, result = 
    (Ext_list.fold_right (fun tag (nullary, acc) -> 
         match nullary, tag with 
         | (`Nothing | `Null), 
           Parsetree.Rtag (label, attrs, true,  [])
           -> 
           begin match Ast_attributes.iter_process_bs_string_as attrs with 
             | Some name -> 
               `Null, ((Ext_pervasives.hash_variant label, name) :: acc )

             | None -> 
               `Null, ((Ext_pervasives.hash_variant label, label) :: acc )
           end
         | (`Nothing | `NonNull), Parsetree.Rtag(label, attrs, false, ([ _ ])) 
           -> 
           begin match Ast_attributes.iter_process_bs_string_as attrs with 
             | Some name -> 
               `NonNull, ((Ext_pervasives.hash_variant label, name) :: acc)
             | None -> 
               `NonNull, ((Ext_pervasives.hash_variant label, label) :: acc)
           end
         | _ -> Bs_syntaxerr.err ptyp_loc Invalid_bs_string_type

       ) row_fields (`Nothing, [])) in 
  (match case with 
   | `Nothing -> Bs_syntaxerr.err ptyp_loc Invalid_bs_string_type
   | `Null -> External_arg_spec.NullString result 
   | `NonNull -> NonNullString result)

  
  let is_enum row_fields = 
    List.for_all (fun (x : Parsetree.row_field) -> 
      match x with 
      | Rtag(_label,_attrs,true, []) -> true 
      | _ -> false
    ) row_fields
