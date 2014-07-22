
(*
copyright (c) 2013-2014, simon cruanes
all rights reserved.

redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 IO Monad} *)

type 'a t
type 'a io = 'a t

type 'a or_error = [ `Ok of 'a | `Error of string ]

val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
(** wait for the result of an action, then use a function to build a
    new action and execute it *)

val return : 'a -> 'a t
(** Just return a value *)

val repeat : int -> 'a t -> 'a list t
(** Repeat an IO action as many times as required *)

val repeat' : int -> 'a t -> unit t
(** Same as {!repeat}, but ignores the result *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** Map values *)

val (>|=) : 'a t -> ('a -> 'b) -> 'b t

val pure : 'a -> 'a t
val (<*>) : ('a -> 'b) t -> 'a t -> 'b t

val lift : ('a -> 'b) -> 'a t -> 'b t
(** Synonym to {!map} *)

val lift2 : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t
val lift3 : ('a -> 'b -> 'c -> 'd) -> 'a t -> 'b t -> 'c t -> 'd t

val run : 'a t -> 'a or_error
(** Run an IO action.
    @return either [`Ok x] when [x] is the successful result of the
      computation, or some [`Error "message"] *)

val register_printer : (exn -> string option) -> unit
(** [register_printer p] register [p] as a possible failure printer.
    If [run a] raises an exception [e], [p e] is evaluated. If [p e = Some msg]
    then the error message will be [msg], otherwise other printers will
    be tried *)

(** {2 Standard Wrappers} *)

(** {6 Input} *)

val with_in : ?flags:open_flag list -> string -> (in_channel -> 'a t) -> 'a t

val read : in_channel -> string -> int -> int -> int t

val read_line : in_channel -> string t

(** {6 Output} *)

val with_out : ?flags:open_flag list -> string -> (out_channel -> 'a t) -> 'a t

val write : out_channel -> string -> int -> int -> unit t

val write_str : out_channel -> string -> unit t

val write_buf : out_channel -> Buffer.t -> unit t

val flush : out_channel -> unit t

(** {2 Streams} *)

(* XXX: WIP
module Seq : sig
  type +'a t

  val map : ('a -> 'b io) -> 'a t -> 'b t
  (** Map values with actions *)

  val map_pure : ('a -> 'b) -> 'a t -> 'b t
  (** Map values with a pure function *)

  val filter_map : ('a -> 'b option) -> 'a t -> 'b t

  val flat_map : ('a -> 'b t) -> 'a t -> 'b t
  (** Map each value to a sub sequence of values *)

  val general_iter : ('b -> 'a -> [`Stop | `Continue of ('b * 'c option)]) ->
                      'b -> 'a t -> 'c t
  (** [general_iter f acc seq] performs a [filter_map] over [seq],
      using [f]. [f] is given a state and the current value, and
      can either return [`Stop] to indicate it stops traversing,
      or [`Continue (st, c)] where [st] is the new state and
      [c] an optional output value.
      The result is the stream of values output by [f] *)

  (** {6 Consume} *)

  val iter : ('a -> _ io) -> 'a t -> unit io
  (** Iterate on the stream, with an action for each element *)

  (** {6 Standard Wrappers} *)

  type 'a step_result =
    | Yield of 'a
    | Stop

  type 'a gen = unit -> 'a step_result io

  val of_fun : 'a gen io -> 'a t
  (** Create a stream from a function that yields an element or stops *)

  val with_in : ?flags:open_flag list -> string -> 'a t

  val lines : in_channel io -> string t
  (** Lines of an input channel *)

  val output : ?sep:string -> out_channel -> string t -> unit io
  (** [output oc seq] outputs every value of [seq] into [oc], separated
      with the optional argument [sep] (default: ["\n"]) *)

  val length : _ t -> int io
  (** Length of the stream *)

  val fold : ('b -> 'a -> 'b io) -> 'b -> 'a t -> 'b io
  (** [fold f acc seq] folds over [seq], consuming it. Every call to [f]
      has the right to return an IO value. *)
end
*)

(** {2 Low level access} *)
module Raw : sig
  val wrap : (unit -> 'a) -> 'a t
  (** [wrap f] is the IO action that, when executed, returns [f ()].
      [f] should be callable as many times as required *)
end