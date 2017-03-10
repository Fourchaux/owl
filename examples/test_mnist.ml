(* Test neural network on MNIST *)

let print_image x =
  let open Owl in
  let x = Mat.reshape 28 28 x in
  Mat.iter_rows (fun v ->
    Vec.iter (function 0. -> Printf.printf " " | _ -> Printf.printf "■") v;
    print_endline "";
  ) x

let print_random x m =
  let open Owl in
  Mat.draw_rows x m |> fst |> Mat.iter_rows print_image

let load_mnist_train_data () =
  let open Owl in
  let p = Owl_utils.local_data_path () in
  Mat.load (p ^ "mnist-train-images"),
  Mat.load (p ^ "mnist-train-labels")
  |> Mat.transpose
  |> Mat.map_by_row 10 (fun a -> Vec.unit_basis ~typ:Row 10 (int_of_float a.{0,0}))

let load_mnist_test_data () =
  let open Owl in
  let p = Owl_utils.local_data_path () in
  Mat.load (p ^ "mnist-test-images"),
  Mat.load (p ^ "mnist-test-labels") |> Mat.transpose

let draw_samples x y n =
  let open Owl in
  let x, l = Mat.draw_rows ~replacement:false x n in
  let y = Mat.rows y l in
  x, y

(* nn related code *)

open Owl_algodiff_ad

type layer = {
  mutable w : t;
  mutable b : t;
  a : t -> t;
}

type network = { layers : layer array }

let run_layer x l = Maths.((x $@ l.w) + l.b) |> l.a

let run_network x nn = Array.fold_left run_layer x nn.layers
(*
let l0 = {
  w = Maths.(Mat.uniform 784 300 * F 0.15 - F 0.075);
  b = Mat.zeros 1 300;
  a = Maths.tanh;
}

let l1 = {
  w = Maths.(Mat.uniform 300 10 * F 0.15 - F 0.075);
  b = Mat.zeros 1 10;
  a = Mat.map_by_row Maths.softmax;
}

let nn = {layers = [|l0; l1|]}

let backprop nn eta epoch x y =
  let t = tag () in
  for i = 1 to epoch do
    Gc.print_stat stdout;
    Array.iter (fun l ->
      l.w <- make_reverse l.w t;
      l.b <- make_reverse l.b t;
    ) nn.layers;
    let loss = ref (F 0.) in
    Mat.iter2_rows (fun u v ->
      (* print_image (Mat.unpack_box u); flush_all (); *)
      loss := Maths.(cross_entropy v (run_network u nn) + !loss)
    ) x y;
    loss := Maths.(!loss / F (Mat.row_num x |> float_of_int));
    (* Printf.printf "#%i : reverse_prop" i; flush_all (); *)
    reverse_prop (F 1.) !loss;
    Array.iter (fun l ->
      l.w <- Maths.(primal ((primal l.w) - (eta * (adjval l.w))));
      l.b <- Maths.(primal ((primal l.b) - (eta * (adjval l.b))));
    ) nn.layers;
    match (primal !loss) with
    | F loss -> Printf.printf "\n#%i : loss=%g\n\n" i loss; flush_all ()
    | _ -> print_endline "error"
  done

let backprop' nn eta epoch x y =
  let t = tag () in
  for i = 1 to epoch do
    Array.iter (fun l ->
      l.w <- make_reverse l.w t;
      l.b <- make_reverse l.b t;
    ) nn.layers;
    let loss = Maths.(cross_entropy y (run_network x nn) / (F (Mat.row_num x |> float_of_int))) in
    reverse_prop (F 1.) loss;
    Array.iter (fun l ->
      l.w <- Maths.((primal l.w) - (eta * (adjval l.w))) |> primal;
      l.b <- Maths.((primal l.b) - (eta * (adjval l.b))) |> primal;
    ) nn.layers;
    Gc.compact ();
    match (primal loss) with
    | F loss -> Printf.printf "#%i : loss=%g\n" i loss; flush_all ()
    | _ -> print_endline "error"
  done
*)
let backprop'' nn eta epoch x y =
  let t = tag () in
  Array.iter (fun l ->
    l.w <- make_reverse l.w t;
    l.b <- make_reverse l.b t;
  ) nn.layers;
  let loss = Maths.(cross_entropy y (run_network x nn) / (F (Mat.row_num x |> float_of_int))) in
  reverse_prop (F 1.) loss;
  Array.iter (fun l ->
    l.w <- Maths.((primal l.w) - (eta * (adjval l.w))) |> primal;
    l.b <- Maths.((primal l.b) - (eta * (adjval l.b))) |> primal;
  ) nn.layers;
  match (primal loss) with
  | F loss -> Printf.printf "#%i : loss=%g\n" epoch loss; flush_all ()
  | _ -> print_endline "error"

let test_model nn x y =
  Mat.iter2_rows (fun u v ->
    print_image (unpack_mat u);
    let p = run_network u nn |> unpack_mat in
    Owl.Mat.print p;
    Printf.printf "prediction: %i\n" (let _, _, j = Owl.Mat.max_i p in j);
    flush_all ()
  ) x y
(*
let test_1 () =
  print_endline "test MNIST";
  let x, y = load_mnist_train_data () in
  let x, y = draw_samples x y 1000 in
  backprop' nn (F 0.01) 50 (Mat x) (Mat y);
  let x, y = load_mnist_test_data () in
  let x, y = draw_samples x y 10 in
  test_model nn (Mat x) (Mat y)
*)
let _ =
let l0 = {
  w = Maths.(Mat.uniform 784 300 * F 0.15 - F 0.075);
  b = Mat.zeros 1 300;
  a = Maths.tanh;
}
in
let l1 = {
  w = Maths.(Mat.uniform 300 10 * F 0.15 - F 0.075);
  b = Mat.zeros 1 10;
  a = Mat.map_by_row Maths.softmax;
}
in
let nn = {layers = [|l0; l1|]}
in
  print_endline "test MNIST";
  let x, y = load_mnist_train_data () in
  for i = 1 to 500 do
    let x', y' = draw_samples x y 100 in
    backprop'' nn (F 0.01) i (Mat x') (Mat y');
    Gc.full_major ()
  done;
  let x, y = load_mnist_test_data () in
  let x, y = draw_samples x y 10 in
  test_model nn (Mat x) (Mat y)
