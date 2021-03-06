defmodule Wemo.Switch.ChangeStatus do
  import SweetXml

  @soap_client Application.get_env(:wemo, :soap_client, Wemo.Switch.Client.SoapClient)

  @typedoc """
    Switch change status atom followed by the newly applied state.
  """
  @type result :: {:ok|:no_change, 0|1}

  @spec set_state(0|1, Wemo.Switch.Metadata) :: result
  def set_state(state, switch) when state in [0, 1] do
    result = state
    |> build_state_change_xml
    |> post_state_change_request(switch)
    |> parse_state_change_response

    {result, state}
  end

  defp build_state_change_xml(state) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
    <u:SetBinaryState xmlns:u="urn:Belkin:service:basicevent:1">
    <BinaryState>#{state}</BinaryState>
    </u:SetBinaryState>
    </s:Body>
    </s:Envelope>
    """
  end

  defp post_state_change_request(xml, switch) do
    @soap_client.post_request(
      xml,
      "#{switch.base_url}/upnp/control/basicevent1",
      "urn:Belkin:service:basicevent:1#SetBinaryState)"
    )
  end

  defp parse_state_change_response(response_body) do
    state = xpath(response_body, ~x"//s:Envelope/s:Body/u:SetBinaryStateResponse/BinaryState/text()")

    case state do
      '0' -> :ok
      '1' -> :ok
      'Error' -> :no_change
    end
  end
end
