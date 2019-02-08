module Data.Dictionary exposing
    ( DictValidationError(..)
    , Dictionary
    , added
    , empty
    , findFirstError
    , get
    , nextEntry
    , randomEntry
    , replacedWith
    , without
    )

import Array exposing (Array)
import Data.Entry as Entry exposing (Entry, EntryValidationError)
import Random exposing (Seed)
import Url


type alias Dictionary =
    Array Entry


type DictValidationError
    = Duplicate String
    | InvalidEntry Entry EntryValidationError


without : Entry -> Dictionary -> Dictionary
without entry =
    Array.filter ((/=) entry)


empty : Dictionary
empty =
    Array.empty


get : String -> Dictionary -> Entry
get de dict =
    let
        emptyEntry =
            Entry.empty

        decoded =
            Url.percentDecode de |> Maybe.withDefault de
    in
    dict
        |> Array.filter (\e -> e.de == decoded)
        |> Array.toList
        |> List.head
        |> Maybe.withDefault { emptyEntry | de = decoded }


nextEntry : String -> Dictionary -> Maybe Entry
nextEntry index dict =
    let
        numberedDict =
            Array.indexedMap (\n entry -> ( n, entry )) dict

        numberForIndex =
            numberedDict
                |> Array.filter (\( _, entry ) -> entry.de == index)
                |> Array.map (\( n, _ ) -> n)
                |> Array.get 0
    in
    numberForIndex
        |> Maybe.andThen
            (\nfi ->
                Array.get
                    (modBy (Array.length dict) (nfi + 1))
                    dict
            )


randomEntry : Seed -> Dictionary -> ( Maybe Entry, Seed )
randomEntry seed entries =
    let
        ( index, nextSeed ) =
            Random.step
                (Random.int 0 (Array.length entries - 1))
                seed
    in
    ( entries |> Array.get index
    , nextSeed
    )


findFirstError : Dictionary -> Maybe DictValidationError
findFirstError dict =
    let
        collectError entry =
            Result.andThen
                (\uniqueItems ->
                    if List.member entry.de uniqueItems then
                        Err (Duplicate entry.de)

                    else
                        case Entry.findFirstError entry of
                            Just err ->
                                Err (InvalidEntry entry err)

                            Nothing ->
                                Ok (entry.de :: uniqueItems)
                )

        result =
            dict
                |> Array.toList
                |> List.foldl collectError (Ok [])
    in
    case result of
        Err e ->
            Just e

        Ok _ ->
            Nothing


replacedWith : Entry -> Entry -> Dictionary -> Dictionary
replacedWith original replacement dict =
    dict
        |> Array.map
            (\e ->
                if e == original then
                    replacement

                else
                    e
            )


added : Entry -> Dictionary -> Dictionary
added entry dict =
    dict |> Array.append ([ entry ] |> Array.fromList)
