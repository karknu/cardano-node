module Cardano.CLI.Ping
  ( PingCommand(..)
  , PingCmdError(..)
  , parsePingCommand
  , runPingCommand
  , renderPingCmdError
  ) where

import           Cardano.Prelude

import qualified Options.Applicative as Opt

data PingCommand = PingCommand

data PingCmdError = PingCmdError

runPingCommand :: ExceptT PingCmdError IO ()
runPingCommand = return ()

renderPingCmdError :: PingCmdError -> Text
renderPingCmdError _err = "TODO"

parsePingCommand :: Opt.Parser PingCommand
parsePingCommand = pure PingCommand
